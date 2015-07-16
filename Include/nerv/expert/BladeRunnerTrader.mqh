#include <nerv/core.mqh>
#include <nerv/expert/PeriodTrader.mqh>
#include <nerv/math.mqh>

/*
Trading strategy based on the descriptino found on the page:
http://www.authenticfx.com/free-forex-trading-strategy.html
*/

enum ENUM_BR_BIAS
{
  BIAS_NONE,
  BIAS_LONG,
  BIAS_SHORT
};

class BladeRunnerTrader : public nvPeriodTrader
{
protected:
  int _maHandle;  // handle for our Moving Average indicator
  int _ma4Handle;  // handle for our Moving Average indicator
  double _maVal[]; // Dynamic array to hold the values of Moving Average for each bars
  double _ma4Val[]; // Dynamic array to hold the values of Moving Average of period 4 for each bars
  MqlRates _mrate[];

  ENUM_BR_BIAS _bias;
  bool _signaled;
  double _marginSig;
  int _TKP;
  double _lot;
  double _currentBase;
  double _currentHigh;
  double _currentLow;
  double _openBarCount;

  // Arrays of previous positive and negative delta values,
  // Used for the computation of the variance/mean values:
  nvVecd _deltas;
  bool _initialized;

public:
  BladeRunnerTrader(const nvSecurity& sec, ENUM_TIMEFRAMES period) : nvPeriodTrader(sec,period)
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

    // Initialize the bias:
    _bias = BIAS_NONE;

    // Number of sigmas to consider when evaluating the bias margin:
    _marginSig = 1.0;

    // Take profit level:
    _TKP = 1000;

    // Lot size:
    _lot = 0.1;

    int len = 250;
    _deltas.resize(len);
    _initialized = false;
  }

  ~BladeRunnerTrader()
  {
    logDEBUG("Deleting indicators...")
    
    //--- Release our indicator handles
    IndicatorRelease(_maHandle);
    IndicatorRelease(_ma4Handle);
  }

  void handleBar()
  {
    string symbol = _security.getSymbol();

    // Add here the computation of the variance of the positive/negative delta values.
     // TODO: clarify what value to use here ?

    if(!_initialized) 
    {
      logDEBUG("Initializing delta statistics...")
      int ilen = (int)_deltas.size();

      // Retrieve the previous rates, and MA20 values:
      // Note that we start with an offset of one because the previous bar details will be 
      // retrieved just after the initialization anyway.
      CHECK(CopyRates(symbol,_period,1,ilen,_mrate)==ilen,"Cannot copy the latest rates");
      CHECK(CopyBuffer(_maHandle,0,1,ilen,_maVal)==ilen,"Cannot copy MA buffer 0");

      // We iterate on each element:
      for(int i=0;i<ilen;++i)
      {
        double delta = _mrate[i].close - _maVal[0];
        _deltas.push_back(delta);
      }

      _initialized = true;
    }


    // MqlTick latest_price;
    MqlTick latest_price;
    CHECK(SymbolInfoTick(symbol,latest_price),"Cannot retrieve latest price.")

    // Get the details of the latest 3 bars
    CHECK(CopyRates(symbol,_period,0,3,_mrate)==3,"Cannot copy the latest rates");
    CHECK(CopyBuffer(_maHandle,0,0,3,_maVal)==3,"Cannot copy MA buffer 0");
    CHECK(CopyBuffer(_ma4Handle,0,0,3,_ma4Val)==3,"Cannot copy MA buffer 0");

    double prev_ema = _maVal[0];
    double prev_ema4 = _ma4Val[0];
    double point = _security.getPoint();
    int digits = _security.getDigits();
    double pclose = _mrate[0].close;
    // logDEBUG("pclose="<<pclose<<", prev_ema="<<prev_ema)
    // logDEBUG("delta="<<NormalizeDouble(pclose-prev_ema,digits))

    double delta = pclose - prev_ema;
    _deltas.push_back(delta);

    // If we currently have a position opened, we use the EMA20 value to update the stop loss if possible:
    if(selectPosition())
    {
      _openBarCount += 1.0;
      double maxBar = 15.0; // TODO: compute this value as a statistic parameter.

      double coeff = MathMin(_openBarCount/maxBar,1.0)*2.0-1.0;
      coeff = 1.0/(1.0 + exp(-coeff));
      double nsl = prev_ema + coeff*(prev_ema4 - prev_ema);

      double stoploss = PositionGetDouble(POSITION_SL);
      bool isBuy = PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
      nsl = isBuy ? MathMax(nsl,stoploss) : MathMin(nsl,stoploss);
      if(nsl!=stoploss) {

        updateSLTP(nsl);
      }

      _bias = BIAS_NONE;
      return;
    }

    // There is currently no position opened, so we check if we should open one:
    if (_bias == BIAS_NONE) {
      // Compute the current margin from the previous deltas:
      double mean = _deltas.mean();
      double sig = _deltas.deviation();

      double pmargin = mean+sig*_marginSig;
      double nmargin = mean-sig*_marginSig;

      // Select our current bias depending on the current price location:
      if (delta > pmargin)
      {
        // It seems prices are going up:
        _bias = BIAS_LONG;
        _currentBase = prev_ema;
        _currentHigh = pclose;
        logDEBUG("Detected LONG bias.")
      }

      if (delta < nmargin)
      {
        // It seems prices are going down:
        _bias = BIAS_SHORT;
        _currentBase = prev_ema;
        _currentLow = pclose;
        logDEBUG("Detected SHORT bias.")
      }
    }

    double fallbackRatio = 0.5;

    if (_bias == BIAS_LONG)
    {
      if (pclose > _currentHigh)
      {
        // update the references:
        _currentHigh = pclose;
        _currentBase = prev_ema;
      }

      // If the price goes down too much we cancel the bias:
      if (pclose < prev_ema)
      {
        logDEBUG("Cancelling LONG bias.")
        _bias = BIAS_NONE;
        _signaled = false;
        return; // do nothing more.
      }

      if (_signaled) {
        // We already got a signal candlestick, so we check if the previous candlestick confirmed that signal:
        // To get a confirmation we would expect the close price of the previous stick to be higher than the close of the 
        // stick before it:
        if(pclose>_mrate[1].close) {
          // This is a confirmation of the signal, so we should place a buy order:
          // TODO: place a pending order instead ?
          double price = latest_price.ask;
          double sl = prev_ema;
          double tp = 0.0; //latest_price.ask+ _TKP*point;

          logDEBUG("Placing buy order")
          sendDealOrder(ORDER_TYPE_BUY,_lot,price,sl,tp);
          _openBarCount = 0.0;
          _bias = BIAS_NONE;
        }

        // cancel this signal:
        // logDEBUG("Cancelling LONG signal.")
        _signaled = false;
      }
      else {
        // We didn't get any signal yet, check the previous bar:
        // double thres = (prev_ema+_margin*point*0.25);
        // if(_mrate[0].low < thres && pclose > thres && pclose > _mrate[0].open)
        // {
        //   logDEBUG("Detected LONG signal.")
        //   _signaled = true;
        // }

        // We consider we get a signal when we fall by 75% from the current High:
        if((pclose - _currentBase)/(_currentHigh - _currentBase) < fallbackRatio)
        {
          logDEBUG("Detected LONG signal.")
          _signaled = true;
        }
      }
    }

    if (_bias == BIAS_SHORT)
    {
      if (pclose < _currentLow)
      {
        // update the references:
        _currentLow = pclose;
        _currentBase = prev_ema;
      }


      // If the price goes down too much we cancel the bias:
      if (pclose > prev_ema)
      {
        logDEBUG("Cancelling SHORT bias.")
        _bias = BIAS_NONE;
        _signaled = false;
        return; // do nothing more.
      }

      if (_signaled) {
        // We already got a signal candlestick, so we check if the previous candlestick confirmed that signal:
        // To get a confirmation we would expect the close price of the previous stick to be higher than the close of the 
        // stick before it:
        if(pclose<_mrate[1].close) {
          // This is a confirmation of the signal, so we should place a buy order:
          // TODO: place a pending order instead ?
          double price = latest_price.bid;
          double sl = prev_ema;
          double tp = 0.0; //latest_price.bid - _TKP*point;

          logDEBUG("Placing sell order")
          sendDealOrder(ORDER_TYPE_SELL,_lot,price,sl,tp);
          _openBarCount = 0.0;
          _bias = BIAS_NONE;
        }

        // cancel this signal:
        // logDEBUG("Cancelling SHORT signal.")
        _signaled = false;
      }
      else {
        // We didn't get any signal yet, check the previous bar:
        // double thres = (prev_ema-_margin*point*0.25);
        // if(_mrate[0].high > thres && pclose < thres && pclose < _mrate[0].open)
        // {
        //   logDEBUG("Detected SHORT signal.")
        //   _signaled = true;
        // }

        // We consider we get a signal when we fall by 75% from the current High:
        if((_currentBase - pclose)/(_currentBase - _currentLow) < fallbackRatio)
        {
          logDEBUG("Detected SHORT signal.")
          _signaled = true;
        }        
      }
    }
  }
};
