#include <nerv/core.mqh>
#include <nerv/expert/PeriodTrader.mqh>
#include <nerv/math.mqh>

/*
This trader will try to detect when we are for instance in a bullish trend and the current
price is way either than the MA4 value whereas the MA4 value is itself way higher that the MA20 value
(and same kind of situation for a bearish trend)

In that case, the trader will emit a signal that will be used on a tick by tick basic:
When in a bullish trend, we then place a sell order when we detect that the up tendency is stopped
Take profit is placed on the level of the MA4, and stoploss is "twice higher"
*/

enum ENUM_PT_TREND
{
  TREND_NONE,
  TREND_LONG,
  TREND_SHORT
};

class PeakTrader : public nvPeriodTrader
{
protected:
  int _maHandle;  // handle for our Moving Average indicator
  int _ma4Handle;  // handle for our Moving Average indicator
  double _maVal[]; // Dynamic array to hold the values of Moving Average for each bars
  double _ma4Val[]; // Dynamic array to hold the values of Moving Average of period 4 for each bars
  MqlRates _mrate[];

  double _lot;
  nvVecd _maDeltas;
  double _maMean;
  double _maSig;
  double _maThreshold;
  nvVecd _priceDeltas;
  double _priceMean;
  double _priceSig;
  double _priceThreshold;
  int _priceStatCount;
  nvVecd _tickDeltas;
  double _prevTick;
  double _tickAlpha;
  bool _initialized;
  bool _signaled;
  bool _hasNewBar;
  double _prev_ema4;
  double _prev_ema20;
  double _slMult;
  double _riskDecayMult;

  double _ema4Slope;
  double _slopeAlpha;
  nvVecd _prevSlopes;
  nvVecd _smoothedSlope;

  double _slopeThreshold;
  double _ema4SlopeMean;
  double _ema4SlopeSig;

  double _envelopeThreshold;
  double _prevBalance;
  double _accumLost;
  double _riskAversion;
  double _numStreakLost;
  int _frozenBars;

  nvVecd _equityDeltas;
  int _equityStatCount;
  ENUM_PT_TREND _trend;
  string _symbol;

public:
  PeakTrader(const nvSecurity& sec, ENUM_TIMEFRAMES period, double priceThres, double maThres, double slMult, double slopeThreshold, double riskDecay) : nvPeriodTrader(sec,period)
  {
    // Prepare the moving average indicator:
    _maHandle=iMA(_security.getSymbol(),_period,20,0,MODE_EMA,PRICE_CLOSE);
    _ma4Handle=iMA(_security.getSymbol(),_period,4,0,MODE_EMA,PRICE_CLOSE);
    
    //--- What if handle returns Invalid Handle    
    CHECK(_maHandle>=0 && _ma4Handle>=0,"Invalid indicators handle");

    // the rates arrays
    ArraySetAsSeries(_mrate,true);
    // the MA-20 values arrays
    ArraySetAsSeries(_maVal,true);
    // the MA-4 values arrays
    ArraySetAsSeries(_ma4Val,true);

    // Lot size:
    _lot = 0.1;

    // cache the symbol:
    _symbol = _security.getSymbol();
    
    // Stoploss multiplier:
    _slMult = slMult;
    _riskDecayMult = riskDecay;

    // initialize the new bar flag:
    _hasNewBar = false;

    _envelopeThreshold = 0.0;
    _prevBalance = 0.0;
    _accumLost = 0.0;
    _riskAversion = 0.0;
    _numStreakLost = 0.0;
    _frozenBars = 0;

    // ma threshold given in number of ma sigmas:
    _maThreshold = maThres;

    // price threshold given in number of price sigmas:
    _priceThreshold = priceThres;

    // EMA slope threshold:
    _slopeThreshold = slopeThreshold;

    // Count used to decide if we are ready to trade.
    _priceStatCount = 0;

    // Count to decide if the equity handling is ready:
    _equityStatCount = 0;

    // Initialize the trend:
    _trend = TREND_NONE;
    _signaled = false;

    // resize the statistic vectors:
    int malen = 200;
    int pricelen = 100;
    int ticklen = 4;
    int smoothlen = 7;
    int slopelen = 100;
    int equitylen = 1000.0;

    _maDeltas.resize(malen);
    _priceDeltas.resize(pricelen);
    _tickDeltas.resize(ticklen);
    _smoothedSlope.resize(smoothlen);
    _prevSlopes.resize(slopelen);
    _equityDeltas.resize(equitylen);

    _ema4Slope = 0.0;
    _maMean = 0.0;
    _maSig = 0.0;
    _priceMean = 0.0;
    _priceSig = 0.0;
    _ema4SlopeMean = 0.0;
    _ema4SlopeSig = 0.0;
    _initialized = false;
    _prev_ema4 = 0.0;
    _prev_ema20 = 0.0;

    // tick exponential moving average alpha:
    _tickAlpha = 1.0/(double)ticklen;

    // EMA slope exponential moving average alpha:
    _slopeAlpha = 1.0/(double)smoothlen;
  }

  ~PeakTrader()
  {
    logDEBUG("Deleting indicators...")
    logDEBUG("Was using: priceThreshold: "<<_priceThreshold<<", maThreshold: "<<_maThreshold<<", slMult: "<<_slMult)

    //--- Release our indicator handles
    IndicatorRelease(_maHandle);
    IndicatorRelease(_ma4Handle);
  }

  void updateStats(double ema4, double ema20, double high, double low)
  {
    if(_prev_ema4 == 0.0)
    {
      // init prev ema:
      _prev_ema4 = ema4;
    }

    if(_prev_ema20 == 0.0)
    {
      // init prev ema:
      _prev_ema20 = ema20;
    }

    // Now compute the smoothed MA4 slope:
    _smoothedSlope.push_back(ema4-_prev_ema4);

    _ema4Slope = _smoothedSlope.EMA(_slopeAlpha);

    // Update the statistics on the smoothed slope:
    _prevSlopes.push_back(_ema4Slope);
    _ema4SlopeMean = _prevSlopes.mean();
    _ema4SlopeSig = _prevSlopes.deviation();

    // save prev ema4 value:
    _prev_ema4 = ema4;
    _prev_ema20 = ema20;

    double delta = ema4 - ema20;
    _maDeltas.push_back(delta);
  
    _maMean = _maDeltas.mean();
    _maSig = _maDeltas.deviation();


    // Now that we have the maMean and maSig values, we have an "idea"
    // on how far the MA4 can go from the MA20 value
    // basing ourself on this observation, we now paid attention to the high prices in the bars
    // when the current maDelta is higher that maMean+maSig,
    // And the low prices, when the current maDelta is lower that maMean-maSig
    if(delta > _maMean+_maThreshold*_maSig)
    {
      // This is a bullish bubble, so we consider the high price:
      double pdelta = high - ema4;
      _priceDeltas.push_back(pdelta);
      _priceStatCount++;
      _priceMean = _priceDeltas.mean();
      _priceSig = _priceDeltas.deviation();
      // logDEBUG(TimeCurrent() << ": Current price deviation: "<<_priceSig)
    }
    if(delta < _maMean-_maThreshold*_maSig)
    {
      double pdelta = ema4 - low;
      _priceDeltas.push_back(pdelta);
      _priceStatCount++;
      _priceMean = _priceDeltas.mean();
      _priceSig = _priceDeltas.deviation();
      // logDEBUG(TimeCurrent() << ": Current price deviation: "<<_priceSig)
    }
  }

  void initStatistics(int nblocks)
  {
    logDEBUG("Initializing statistics with "<<nblocks<<" data blocks.");

    // Reset the stats count:
    _priceStatCount = 0;
    int ilen = (int)_maDeltas.size()*nblocks;

    // Retrieve the previous rates, and MA20 values:
    // Note that we start with an offset of one because the previous bar details will be 
    // retrieved just after the initialization anyway.
    CHECK(CopyRates(_symbol,_period,1,ilen,_mrate)==ilen,"Cannot copy the latest rates");
    CHECK(CopyBuffer(_maHandle,0,1,ilen,_maVal)==ilen,"Cannot copy MA20 buffer 0");
    CHECK(CopyBuffer(_ma4Handle,0,1,ilen,_ma4Val)==ilen,"Cannot copy MA4 buffer 0");

    // We iterate on each element:
    for(int i=0;i<ilen;++i)
    {
      updateStats(_ma4Val[ilen-i-1],_maVal[ilen-i-1],_mrate[ilen-i-1].high,_mrate[ilen-i-1].low);
    }
  }

  bool ready()
  {
    return _priceStatCount>=(int)_priceDeltas.size();
  }

  void handleBar()
  {
    if(!_initialized) 
    {
      logDEBUG("Initializing delta statistics...");
      int nblocks=0;
      while(!ready())
      {
        initStatistics(++nblocks);
      }

      _initialized = true;
    }

    // Each time we get a new bar, we update the statistics:
    // Get the details of the latest 4 bars
    CHECK(CopyRates(_symbol,_period,0,1,_mrate)==1,"Cannot copy the latest rates");
    CHECK(CopyBuffer(_maHandle,0,0,1,_maVal)==1,"Cannot copy MA20 buffer 0");
    CHECK(CopyBuffer(_ma4Handle,0,0,1,_ma4Val)==1,"Cannot copy MA4 buffer 0");
    
    // Store the current MA4 value since this is needed to place orders.
    updateStats(_ma4Val[0],_maVal[0],_mrate[0].high,_mrate[0].low);

    // Define if we are currently in trend bubble or not:
    _trend = TREND_NONE;
    double delta = _ma4Val[0] - _maVal[0];

    if(delta > _maMean+_maThreshold*_maSig)
    {
      // logDEBUG("Detected Long bubble.")
      _trend = TREND_LONG;
    }
    if(delta < _maMean-_maThreshold*_maSig)
    {
      // logDEBUG("Detected Short bubble.")
      _trend = TREND_SHORT;
    }

    // Mark that a new bar as arrived, thus a new order could be placed if possible:
    _hasNewBar = true;

    // We need to decay the risk aversion progressively:
    _riskAversion = _riskAversion*_riskDecayMult;
    // logDEBUG("Current risk aversion: "<<_riskAversion)

    // Reduce the number of frozen bars if needed:
    if(_frozenBars>0)
    {
      --_frozenBars;
    }
  }

  void handleTick()
  {
    CHECK(ready(),"Not enough statistic data ?")

    double balance = AccountInfoDouble(ACCOUNT_BALANCE);

    // MqlTick latest_price;
    MqlTick latest_price;
    CHECK(SymbolInfoTick(_symbol,latest_price),"Cannot retrieve latest price.")

    double tick = latest_price.bid;


    if(selectPosition())
    {
      // We update the takeprofit with the newest value of the prev_ema.
      // if(_hasNewBar)
      // {
      //   double sl = PositionGetDouble(POSITION_SL);
      //   double tp = _prev_ema4;
      //   updateSLTP(sl,tp);
      //   _hasNewBar = false;
      // }
      
      // Check if we need to secure the current profits:
      // double sl = PositionGetDouble(POSITION_SL);
      // bool isBuy = PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
      // // Update the stoploss to get closer to the bid price progressively:
      // double nsl = sl + 0.01 * (tick + (isBuy ? -_priceSig: _priceSig) - sl);

      // Update the trailing stop:
      // double nsl = tick + (isBuy ? -1.0: 1.0)*_slMult*_priceSig;
      // nsl = isBuy ? MathMax(nsl,sl) : MathMin(nsl,sl);
      // if(nsl!=sl)
      // {
      //   // logDEBUG("Updated new stoploss: "<<nsl)
      //   updateSLTP(nsl);
      // }

      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double delta = equity-balance;
      _equityDeltas.push_back(delta);
      _equityStatCount++;

      if(_equityStatCount>=(int)_equityDeltas.size())
      {
        // We can use the current equity level to decide if a position should be closed:
        double mean = _equityDeltas.mean();
        double sigma = _equityDeltas.deviation();
        if(delta > mean + 4*sigma)
        {
          // then we close the current position!
          logDEBUG("Closing position since "<<delta<<" > "<<(mean + 3*sigma))
          closePosition();
        }
      }

      return;
    }

    // init the prev balance value:
    if(_prevBalance == 0.0)
    {
      _prevBalance = balance;
    }

    // each time we receive a new balance value, it means a deal is terminated.
    // And we should react depending on the current tendency to avoid large drawdowns:
    if(_prevBalance != balance)
    {
      logDEBUG(TimeCurrent() << ": Detected new balance value: "<<balance)
      double delta = 100.0 * (balance - _prevBalance)/balance; // in percentage.

      // We then keep the notion of accumulated lost:
      if(delta<0.0) {
        _numStreakLost+=1.0;

        _accumLost += -delta;
        // And we build an exponential risk aversion on top of that:
        // _riskAversion = (MathExp((_numStreakLost>4.0?_numStreakLost/4.0:0.0)+_accumLost/1.0)-1.0); 
        _riskAversion = 0.0; //(MathExp(_accumLost/1.0)-1.0); 
        logDEBUG("Accumulated lost in percent: "<< _accumLost)

        // Implement the notion of freeze:
        if(_numStreakLost>=6)
        {
          logDEBUG("Drawdown detected applying freeze.")
          _numStreakLost = 0.0;
          _frozenBars = 10;
        }
      }
      else
      {
        // reset the accumulated lost:
        _accumLost = 0.0;
        _numStreakLost = 0.0;
        _riskAversion = 0.0;
      }

      _prevBalance = balance;
    }

    if(_frozenBars>0)
    {
      // Don't look for any trade, we are currently frozen due to drawdown:
      return;
    }

    // We don't have anything to do if we are not in a trend bubble:
    if(_trend == TREND_NONE)
    {
      return;
    }

    // logDEBUG("Entering handleTick()")

    if(_prevTick==0.0)
    {
      // initialize the prev tick value:
      _prevTick = tick;
    }

    // So first we update the tick deltas with the latest tick info,
    // This will depend on the current trend considered.
    double tdelta = _trend==TREND_LONG ? tick - _prevTick : _prevTick - tick;
    _prevTick = tick;
    
    // Add this delta to the vector:
    _tickDeltas.push_back(tdelta);

    // So we received a new tick, statistics are ready and we are not in a position yet.
    // So first we check if we are currently in a signaled state:
    if(_signaled) {
      // logDEBUG("Handling signal")
      // the previous ticks entered the alert zone, so now we just need to decide if we should buy/sell right now 
      // or wait a bit longer for the tick trend to finish.
      // To do that we should use the mean of the latest tick deltas

      // Now check the current EMA: it should be positive, otherwise, we place an order!
      if(_tickDeltas.EMA(_tickAlpha)<0.0)
      {
        if(_hasNewBar || true) // allow only one order per bar.
        {
          sendDeviationOrder(latest_price.ask);
          // sendMA20InvertOrder(latest_price.ask);          
        }
        _hasNewBar = false;

        // terminate this signal:
        _signaled = false;
      }

      // The tick trend is still not finished, so we wait...
    }
    else {
      _signaled = checkDeviationSignal();
      // _signaled = checkMA20InvertSignal();
    }

  }

  double getLotSize(double mult)
  {
    double num =  mult*_lot / (1.0 + _riskAversion);
    num = MathFloor(num*100)/100;
    logDEBUG("Using lot size: "<<num);
    return num;
  }

  void sendDeviationOrder(double ask)
  {
    double lotsize = getLotSize(1.0);

    // place the order depending on the current trend:
    if(_trend==TREND_LONG) {
      // We place a sell order in that case:
      sendDealOrder(ORDER_TYPE_SELL,lotsize,_prevTick,_prevTick+_slMult*_priceSig,_prev_ema4);
    }
    else {
      // We place a buy order in that case:
      sendDealOrder(ORDER_TYPE_BUY,lotsize,ask,_prevTick-_slMult*_priceSig,_prev_ema4);
    }
  }

  void sendMA20InvertOrder(double ask)
  {
    // place the order depending on the current trend:
    double delta = MathAbs(_prev_ema4-_prev_ema20);
    double lotsize = getLotSize(1.0);

    if(_trend==TREND_LONG) {
      // We place a sell order in that case:
      sendDealOrder(ORDER_TYPE_SELL,lotsize,_prevTick,_prevTick+_slMult*delta,_prev_ema4);
    }
    else {
      // We place a buy order in that case:
      sendDealOrder(ORDER_TYPE_BUY,lotsize,ask,_prevTick-_slMult*delta,_prev_ema4);
    }
  }

  bool checkMA20InvertSignal()
  {
    // For the invert entry we consider the threshold to be proportional to the delta of MA4 and MA20.
    double delta = MathAbs(_prev_ema4-_prev_ema20);
    return ((_trend==TREND_LONG && _prevTick > (_prev_ema4 + _priceThreshold*delta))
      || (_trend==TREND_SHORT && _prevTick < (_prev_ema4 - _priceThreshold*delta)));
  }

  bool checkDeviationSignal()
  {
    // logDEBUG("Checking for signal...")
    // Check if the market is not current trending too much:
    // if(MathAbs(_ema4Slope - _ema4SlopeMean) > _slopeThreshold*_ema4SlopeSig)
    // {
    //   // Current trend is too strong.
    //   // We just don't want to take the risk here.
    //   return false;
    // }

    double delta = MathAbs(_prev_ema4-_prev_ema20);
    // If we are not at least one delta higher that the current prev_ema4, then we should not signal anything:
    if((_trend==TREND_LONG && _prevTick < (_prev_ema4 + _envelopeThreshold*delta))
      || (_trend==TREND_SHORT && _prevTick > (_prev_ema4 - _envelopeThreshold*delta)))
    {
      return false;
    }

    // There is currently no signal for an interesting tick behavior.
    // So just check if the current tick is goind too far.
    // This again will depend on the current trend.
    return ((_trend==TREND_LONG && _prevTick > _prev_ema4+_priceMean+_priceThreshold*_priceSig && _tickDeltas.EMA(_tickAlpha)>0.0)
      || (_trend==TREND_SHORT && _prevTick < _prev_ema4-_priceMean-_priceThreshold*_priceSig && _tickDeltas.EMA(_tickAlpha)>0.0));
  }
};
