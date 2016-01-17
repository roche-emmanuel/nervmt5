#include <nerv/core.mqh>
#include <nerv/enums.mqh>

#include <nerv/trading/SecurityTrader.mqh>

/*
Class: nvZoneRecoveryTrader

Base class representing a trader 
*/
class nvZoneRecoveryTrader : public nvSecurityTrader
{
protected:
  // primary handle for ATR:
  int _patrHandle;

  // handle for ATR:
  int _atrHandle;

  // Heiken Ashi primary indicator:
  int _phaHandle;

  // Heiken Ashi entry indicator:
  int _ehaHandle;

  // Moving average handle:
  int _ma20Handle;

  // MqlRates _mrate[];
  double _atrVal[];
  double _ma20Val[];
  double _sigVal[];

  // statistic window size:
  int _statMACount;
  int _statATRCount;

  // Number of MA values to consider when computing the mean slope:
  int _fastMACount;
  
  int _entryHACount;

  // Normalized volatility threshold:
  double _volatilityThreshold;

  // current lot size:
  double _lotSize;

  // current volatility value:
  double _volatility;

  // Flag set to specify if we should enter another trader for dollar cost
  // averaging.
  bool _needAveraging;

  // Number of averaging count:
  int _averagingCount;

  // Latest position entry:
  double _entryPrice;

  // previous confidence values array:
  double _confidenceVals[];

  // maximum number of confidence values:
  int _confidenceCount;

public:
  /*
    Class constructor.
  */
  nvZoneRecoveryTrader(string symbol,
    ENUM_TIMEFRAMES patrPeriod,
    ENUM_TIMEFRAMES atrPeriod,
    ENUM_TIMEFRAMES phaPeriod, 
    ENUM_TIMEFRAMES maPeriod,
    ENUM_TIMEFRAMES ehaPeriod,
    ENUM_TIMEFRAMES s2haPeriod
    )
    :nvSecurityTrader(symbol)
  {
    _patrHandle = iATR(_symbol,patrPeriod,14);
    CHECK(_patrHandle>=0,"Invalid ATR handle");

    _atrHandle = iATR(_symbol,atrPeriod,14);
    CHECK(_atrHandle>=0,"Invalid ATR handle");

    _phaHandle=iCustom(_symbol,phaPeriod,"nerv\\HeikenAshi");
    CHECK(_phaHandle>=0,"Invalid Primary Heiken Ashi handle");

    _ma20Handle=iMA(_symbol,maPeriod,20,0,MODE_EMA,PRICE_CLOSE);
    CHECK(_ma20Handle>=0,"Invalid Moving average handle");

    _ehaHandle=iCustom(_symbol,ehaPeriod,"nerv\\HeikenAshi");
    CHECK(_ehaHandle>=0,"Invalid Entry Heiken Ashi handle");

    _statMACount = 500;
    _statATRCount = 500;
    _confidenceCount = 100;

    _fastMACount = 5;
    _entryHACount = 4;
    _volatilityThreshold = 0.5;
    _lotSize = 0.0;
    _volatility = 0.0;
    _averagingCount = 0;

    ArraySetAsSeries(_atrVal,true);
    ArraySetAsSeries(_ma20Val,true);
    ArraySetAsSeries(_sigVal,true);

    _riskLevel = 0.1;
  }

  /*
    Copy constructor
  */
  nvZoneRecoveryTrader(const nvZoneRecoveryTrader& rhs) : nvSecurityTrader("")
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvZoneRecoveryTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvZoneRecoveryTrader()
  {
    logDEBUG("Deleting ZoneRecoveryTrader")
    IndicatorRelease(_patrHandle);
    IndicatorRelease(_atrHandle);
    IndicatorRelease(_phaHandle);
    IndicatorRelease(_ehaHandle);
    IndicatorRelease(_ma20Handle);
  }
  
  /*
  Function: getPrimaryDirection
  
  Retrieve the primary direction of the market
  */
  double getPrimaryDirection()
  {
    // First we need to check what the primary direction is
    // using the primary Heiken Ashi indicator:
    double phaVals[];
    CHECK_RET(CopyBuffer(_phaHandle,4,1,1,phaVals)==1,0.0,"Cannot copy ATR buffer 0");

    //  Here we might also consider a frequency ratio on the last x timeframe
    // for the primary direction indication maybe ?
    return phaVals[0]>0.5 ? -1.0 : 1.0;    
  }
    
  /*
  Function: getMarketTrend
  
  Retrieve the current market trend as a normalized value
  basically between [-6,6], but because of the sigmoid transformation
  we get into the range (-1,1)
  */
  double getMarketTrend()
  {
    // Then we need to get the EMA values:
    CHECK_RET(CopyBuffer(_ma20Handle,0,1,_statMACount,_ma20Val)==_statMACount,0.0,"Cannot copy MA buffer 0");

    // Compute the statistics on the slope of the EMA:
    int len = ArraySize( _ma20Val );
    CHECK_RET(len == _statMACount,0.0,"Invalid count of MA values")

    // Prepare the slope array:
    double maSlopes[];
    ArrayResize( maSlopes, len-1 );
    for(int i=0;i<(len-1);++i)
    {
      // Keep in mind that the EMA array is accessed as time serie:
      maSlopes[i] = _ma20Val[i] - _ma20Val[i+1];
    }

    // compute the mean and devs of the slope:
    double slopeMean = nvGetMeanEstimate(maSlopes);
    double slopeDev = nvGetStdDevEstimate(maSlopes);

    // Now we consider only the slope mean from the previous n timeframes:
    double fastMASlopes[];
    ArrayResize( fastMASlopes, _fastMACount );
    for(int i=0;i<_fastMACount;++i)
    {
      fastMASlopes[i] = maSlopes[i];
    }

    double slope = nvGetMeanEstimate(fastMASlopes);
    // Normalize the slope value:
    slope = (slope - slopeMean)/slopeDev;

    //  Take sigmoid to stay in the range [-1,1]:

    return (nvSigmoid(slope)-0.5)*2.0;  
  }
  
  /*
  Function: getPriceIndication
  
  Check what is the current price position with respect to the Moving
  Average, will return 1.0 if we are above the MA or -1 if we are under it
  */
  double getPriceIndication()
  {
    double maVal[];
    CHECK_RET(CopyBuffer(_ma20Handle,0,1,1,maVal)==1,0.0,"Cannot copy MA buffer 0");

    MqlTick latest_price;
    CHECK_RET(SymbolInfoTick(_symbol,latest_price),0.0,"Cannot retrieve latest price.")

    return latest_price.bid - maVal[0] > 0 ? 1.0 : -1.0;
  }
  
  /*
  Function: getSignal
  
  Retrieve the current entry/exit signal in the range [-1,1]
  */
  double getSignal()
  {
    // Finally we need to check for an entry signal on the entry
    // Heiken Ashi:
    CHECK_RET(CopyBuffer(_ehaHandle,4,1,_entryHACount,_sigVal)==_entryHACount,0.0,"Cannot copy entry HA buffer 4");      

    // Compute the mean value of the entry signal:
    double sig = nvGetMeanEstimate(_sigVal);
    sig = -(sig-0.5)*2.0; // signal will be in the range [-1,1]
    
    if((sig < 0.0 && _sigVal[0]==0.0) || (sig>0.0 && _sigVal[0]==1.0))
      return 0.0;

    return sig;
  }
  
  /*
  Function: getVolatilityLevel
  
  Retrieve the current normalized volatility
  */
  double getVolatilityLevel()
  {
    CHECK_RET(CopyBuffer(_atrHandle,0,1,_statATRCount,_atrVal)==_statATRCount,0.0,"Cannot copy ATR buffer 0");
    double atrMean = nvGetMeanEstimate(_atrVal);
    double atrDev = nvGetStdDevEstimate(_atrVal,atrMean);

    // Check if we have significant volatility:
    double atr = _atrVal[0];

    return (atr-atrMean)/atrDev;    
  }
  
  /*
  Function: getVolatility
  
  Retrieve the current volatility value
  */
  double getVolatility()
  {
    CHECK_RET(CopyBuffer(_patrHandle,0,1,1,_atrVal)==1,0.0,"Cannot copy ATR buffer 0");
    return _atrVal[0];    
  }


  /*
  Function: computeNormalizedConfidence
  
  Compute a normalized confidence value
  */
  double computeNormalizedConfidence(double conf)
  {
    conf = MathAbs(conf);

    nvAppendArrayElement(_confidenceVals,conf,_confidenceCount);

    if(ArraySize( _confidenceVals ) < 10)
    {
      // just return the raw confidence for now:
      return conf;
    }

    // Start building statistics:
    double cmean = nvGetMeanEstimate(_confidenceVals);
    double cdev = nvGetStdDevEstimate(_confidenceVals, cmean);

    // Normalize the confidence we just got:
    conf = (conf-cmean)/cdev;

    // return the sigmoid to get in the range [0,1]
    return nvSigmoid(conf);
  }
  
  virtual void update(datetime ctime)
  {        
    MqlTick latest_price;
    CHECK(SymbolInfoTick(_symbol,latest_price),"Cannot retrieve latest price.")
    double bid = latest_price.bid;

    // Get the primary direction:
    double pdir = getPrimaryDirection();
    // logDEBUG(TimeCurrent() << ": Primary direction is: "<< pdir)

    // Get the market trend:
    double trend = getMarketTrend();

    //  Get the price indication:
    double pind = getPriceIndication();

    // Get the current signal:
    double sig = getSignal();

    // Retrieve volatility level:
    double level = getVolatilityLevel();

    if(hasPosition())
    {
      // We are already in a position.
      bool isBuy = isLong();

      double profit = getPositionProfit();

      // We need to consider only the signal value at first:
      if(isBuy)
      {
        if(sig < - 0.5)
        {
          // We should normally close this position...
          // So we check if we are currently in profit:
          if(profit>0.0) {
            // logDEBUG("Updating profitable Long position stop loss.")
            // In that case we try to update the current stop loss:
            updateStopLoss(bid - getCurrentSpread());
          }
          else {
            // If we are not in profit, then we need to check if we can improve 
            // our position:
            _needAveraging = true;
          }          
        }

        if(sig > 0.5 && _needAveraging && profit <= 0.0
          && (_entryPrice-getCurrentPrice())> _averagingCount*_volatility/5.0) {
          // We need to check if we are far away enough from the entry price:
          // Perform dollar cost averating:
          logDEBUG("Performing long pos averaging.")
          dollarCostAverage();
        }
      }
      else {
        if(sig > 0.5)
        {
          // We should normally close this position...
          // So we check if we are currently in profit:
          if(profit>0.0) {
            // In that case we try to update the current stop loss:
            // logDEBUG("Updating profitable short position stop loss.")
            updateStopLoss(bid + getCurrentSpread());
          }
          else {
            // If we are not in profit, then we need to check if we can improve 
            // our position:
            _needAveraging = true;
          }          
        }

        if(sig < -0.5 && _needAveraging && profit <= 0.0
          && (getCurrentPrice()-_entryPrice)> _averagingCount*_volatility/5.0) {
          // We need to check if we are far away enough from the entry price:
          // Perform dollar cost averating:
          logDEBUG("Performing short pos averaging.")
          dollarCostAverage();
        }        
      }


      // if(isBuy && bid > (_zoneHigh + _targetProfit))
      // {
      //   // Update the stoploss of the position:
      //   double nsl = bid - MathMin((bid-_zoneHigh)/2.0,_trail);
      //   if( nsl > getStopLoss())
      //   {
      //     updateSLTP(nsl);
      //   } 
      // }

      // if(!isBuy && bid < (_zoneLow - _targetProfit))
      // {
      //   // Update the stoploss of the position:
      //   double nsl = bid + MathMin((_zoneLow-bid)/2.0,_trail);
      //   if( nsl < getStopLoss())
      //   {
      //     updateSLTP(nsl);
      //   }
      // }

      // if(!isBuy && bid > _zoneHigh) 
      // {
      //   toggleHedge(ORDER_TYPE_BUY,latest_price.ask);
      // }

      // if(isBuy && bid < _zoneLow) 
      // {
      //   toggleHedge(ORDER_TYPE_SELL,latest_price.bid);
      // }
    }
    else {
      // Retrieve raw volatility:
      double vol = getVolatility();
      
      // logDEBUG(TimeCurrent() << ": Checking new position, pdir="<<pdir<<", trend="<<trend<<", pind="<<pind<<", sig="<<sig<<", vol="<<vol)

      // We use the current volatility value to define the value
      // that we can put at risk:

      // Check if we should buy or sell:
      if(pdir>0.0 && trend>0.0 && pind>0.0 && sig>0.0)
         // && level>_volatilityThreshold)
      {
        // In that case we should place a buy order,
        double conf = computeNormalizedConfidence(pdir*trend*pind*sig);
        logDEBUG(TimeCurrent() << ": Should open long position with pdir="<<pdir<<", trend="<<trend<<", pind="<<pind<<", sig="<<sig<<", vol="<<vol<<", conf="<<conf)
        openPosition(ORDER_TYPE_BUY,vol,1.0); //conf);
      }

      if(pdir<0.0 && trend<0.0 && pind<0.0 && sig<0.0) 
         // && level>_volatilityThreshold)
      {
        double conf = computeNormalizedConfidence(pdir*trend*pind*sig);
        logDEBUG(TimeCurrent() << ": Should open short position with pdir="<<pdir<<", trend="<<trend<<", pind="<<pind<<", sig="<<sig<<", vol="<<vol<<", conf="<<conf)
        openPosition(ORDER_TYPE_SELL,vol,1.0); //conf);
      }
    }
  }

  /*
  Function: openPosition
  
  Method used to open a position
  */
  void openPosition(ENUM_ORDER_TYPE otype, double volatility, double confidence)
  {
    double totalLot = evaluateLotSize(volatility/nvGetPointSize(_symbol),confidence);
    double lot = nvNormalizeLotSize(totalLot/5.0,_symbol);

    if(lot<0.01) {
      logDEBUG("Detected too small lot size: "<<lot)
      lot = 0.01;
      // return;
    }

    _lotSize = lot;
    _volatility = volatility;
    _entryPrice = getCurrentPrice();

    logDEBUG(TimeCurrent() << ": Entry price: " << _entryPrice)

    // reset averaging count:
    _averagingCount = 1;

    sendDealOrder(_security, otype, _lotSize, 0.0, 0.0, 0.0);

    // Assign the absolute stoploss:
    double oprice = getOpenPrice();
    updateSLTP(_security,oprice + (isLong() ? (-_volatility) : _volatility));
    
    logDEBUG(TimeCurrent() << ": Updated stoploss to " << getStopLoss() << " for sub step "<<_averagingCount)
  }

  /*
  Function: dollarCostAverage
  
  Method used to perform dollar cost averaging when we already have an
  opened position
  */
  void dollarCostAverage()
  {
    if(_averagingCount==5) {
      logDEBUG("Cannot perform dollar cost averaging anymore.")
      return;
    }

    CHECK(hasPosition(),"Dollar cost averaging with no open position.")

    _needAveraging = false;

    // increment the averaging count:
    _averagingCount++;

    logDEBUG(TimeCurrent() << ": Applying dollar cost averaging " << _averagingCount)

    // Add to the currently opened position:
    ENUM_ORDER_TYPE otype = isLong() ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

    sendDealOrder(_security, otype, _lotSize, 0.0, 0.0, 0.0);

    // Assign the absolute stoploss:
    double oprice = getOpenPrice();
    updateSLTP(_security,oprice + (isLong() ? (-_volatility) : _volatility));

    logDEBUG(TimeCurrent() << ": Updated stoploss to " << getStopLoss() << " for sub step "<<_averagingCount)
  }
  
  virtual void onTick()
  {

  }

};
