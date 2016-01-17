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

  // current signal level:
  int _sigLevel;

  // sub signal handles
  int _sigHandles[];

  // counts used for the entry/exit signals:
  int _sigEntryMeanCounts[];
  int _sigExitMeanCounts[];

  ENUM_TIMEFRAMES _sigPeriods[];

  datetime _entryTime;

  double _prevProfit;

  bool _inRecovery;
  double _totalLost;

  double _zoneWidth;
  double _zoneHigh;
  double _zoneLow;
  double _targetProfit;
  double _minGain;
  int _bounceCount;

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
    ENUM_TIMEFRAMES s2haPeriod,
    ENUM_TIMEFRAMES s3haPeriod,
    ENUM_TIMEFRAMES s4haPeriod
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

    appendSignal(ehaPeriod, 4, 3); // 5 min
    appendSignal(s2haPeriod, 1, 1); // 15min
    appendSignal(s3haPeriod, 1, 1); // 30min
    appendSignal(s4haPeriod, 1, 1); // 1hour

    _statMACount = 500;
    _statATRCount = 500;
    _confidenceCount = 100;

    _fastMACount = 5;
    _totalLost = 0.0;

    _inRecovery = false;
    _volatilityThreshold = 0.5;
    _lotSize = 0.0;
    _volatility = 0.0;
    _averagingCount = 0;
    _sigLevel = 0;
    _minGain = nvGetPointSize(_symbol)*10.0;

    ArraySetAsSeries(_atrVal,true);
    ArraySetAsSeries(_ma20Val,true);
    ArraySetAsSeries(_sigVal,true);

    _riskLevel = 0.001;
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
    IndicatorRelease(_ma20Handle);

    int len = ArraySize(_sigHandles);
    for(int i=0;i<len;++i)
    {
      IndicatorRelease(_sigHandles[i]);      
    }
  }
  
  /*
  Function: appendSignal
  
  Append a signal to the list
  */
  void appendSignal(ENUM_TIMEFRAMES period, int entryCount, int exitCount)
  {
    int h=iCustom(_symbol,period,"nerv\\HeikenAshi");
    CHECK(h>=0,"Invalid Entry Heiken Ashi handle");

    nvAppendArrayElement(_sigHandles,h);
    nvAppendArrayElement(_sigPeriods,period); 
    nvAppendArrayElement(_sigEntryMeanCounts,entryCount); 
    nvAppendArrayElement(_sigExitMeanCounts,exitCount); 
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
  double getSignal(int id = 0, bool entry = true)
  {
    // Finally we need to check for an entry signal on the entry
    // Heiken Ashi:
    int count = entry ? _sigEntryMeanCounts[id] : _sigExitMeanCounts[id];
    int handle = _sigHandles[id];

    CHECK_RET(CopyBuffer(handle,4,1,count,_sigVal)==count,0.0,"Cannot copy entry HA buffer 4");      
    CHECK_RET(ArraySize( _sigVal )==count,0.0,"Invalid sig array size");

    // Compute the mean value of the entry signal:
    double sig = nvGetMeanEstimate(_sigVal);
    sig = -(sig-0.5)*2.0; // signal will be in the range [-1,1]
    
    if(id>0 || !entry)
      return sig; // Do not perform any ending test.

    if((sig < 0.0 && _sigVal[0]==0.0) || (sig>0.0 && _sigVal[0]==1.0))
      return 0.0;

    return sig;
  }
  

  /*
  Function: getSubSignal
  
  Retrieve the current entry/exit signal in the range [-1,1]
  */
  bool getSubSignal()
  {
    int len = ArraySize(_sigHandles);
    if(_sigLevel>=len)
      return false; // No more possibility.

    int handle = _sigHandles[_sigLevel];
    ENUM_TIMEFRAMES period = _sigPeriods[_sigLevel];

    // check if we passed the time check:
    int dur = nvGetPeriodDuration(period);

    if((TimeCurrent() - _entryTime) < dur)
    {
      return false;
    }

    if(_averagingCount==5)
    {
      return false;
    }
      
    // Finally we need to check for an entry signal on the entry
    // Heiken Ashi:
    double val[];
    CHECK_RET(CopyBuffer(handle,4,1,1,val)==1,0.0,"Cannot copy entry HA buffer 4");      

    // Compute the mean value of the entry signal:
    double sig = -(val[0]-0.5)*2.0; // signal will be in the range [-1,1]
    if((isLong() && sig>0) || (isShort() && sig<0.0))
    {
      logDEBUG(TimeCurrent() << ": Signaling sub sig "<<_sigLevel)
      _sigLevel++;
      return true;
    }

    return false;
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
  
  void toggleHedge(double entry)
  {
    ENUM_ORDER_TYPE order = isLong() ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;

    // Get the current entry price:
    double prevEntry = getOpenPrice();

    double prevSize = getPositionVolume();

    // close current position:
    closePosition();

    // So first we compute how much money we are about to loose:
    // Taking into account that we pay the bid price:
    // the lost in curreny is the lost in number of points multiplied by the current number of lots
    // And multiplied by the contract size, thus:
    double lost = MathAbs(entry - prevEntry)*prevSize;
    _totalLost += lost;
    
    // Now check if we really want to keep this lot size of if we just accept this loosing trade:
    // double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    // If this current total lost is too big, we may just cut the losses:
    // if( 100.0*nvGetContractValue(_symbol,_totalLost)/balance > _riskLevel )
    // {
    //   logDEBUG("Detected too much risk, stopping lot scale up with total lost of " << _totalLost)
    //   // Stop the scale up:
    //   // prevSize = _lotBaseSize;
    //   return;
    // }

    // Update the new entry value:
    prevEntry = entry;

    // Compute the current band details.

    // we will now want the take profit to be at:
    double tp = order==ORDER_TYPE_BUY ? _zoneHigh + _targetProfit : _zoneLow - _targetProfit;

    // and we want to compute the lot size to ensure we can cover the previous lost:
    // What we will get if successfull is (in points):
    // double gain = (tp - prevEntry) * lotsize;
    // And we want this gain to cover the lost plus say 10 points:
    prevSize = (_totalLost+_minGain)/MathAbs(tp - prevEntry);  
    
    // round this to a value lot number:
    prevSize = nvNormalizeLotSize(prevSize,_symbol);
    _bounceCount++;

    logDEBUG(TimeCurrent() <<": Bounce " << _bounceCount <<": Entering "<< (order==ORDER_TYPE_BUY ? "LONG" : "SHORT") <<" position at "<< prevEntry << " with " << prevSize << " lots. (totalLost: "<<NormalizeDouble(_totalLost,6)<<")")
    if(!sendDealOrder(_security, order, prevSize, 0.0, 0.0, tp))
    {
      // Could not place a new order (too much risk ?)
      // So we just close the current position:
      logDEBUG("Could not open zone recovery position!");
      closePosition();
    };
  }

  /*
  Function: updateRecovery

  Method used to update the recovery state:
  */
  void updateRecovery(MqlTick& latest_price)
  {
    // We already have a position opened
    // We just need to monitor the crossing of the zone recovery borders.
    // Check what is the current position:
    bool isBuy = isLong();
    double bid = latest_price.bid;

    if(isBuy && bid > _zoneHigh + _targetProfit)
    {
      // Update the stoploss of the position:
      updateStopLoss(bid - getCurrentSpread());
    }

    if(!isBuy && bid < _zoneLow - _targetProfit)
    {
      // Update the stoploss of the position:
      updateStopLoss(bid + getCurrentSpread());
    }

    if(!isBuy && bid > _zoneHigh) 
    {
      toggleHedge(latest_price.ask);
    }

    if(isBuy && bid < _zoneLow) 
    {
      toggleHedge(latest_price.bid);
    }    
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
    double sig0 = getSignal(0, hasPosition());
    double sig1 = getSignal(1, hasPosition());
    double sig2 = getSignal(2, hasPosition());

    // Retrieve volatility level:
    double level = getVolatilityLevel();

    if(hasPosition())
    {
      if(_inRecovery)
      {
        updateRecovery(latest_price);
        return;
      }

      // We are already in a position.
      bool isBuy = isLong();

      double profit = getPositionProfit();

      // We need to consider only the signal value at first:
      if(isBuy)
      {
        if(sig0 < - 0.5)
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

        // if(profit<0.0 && sig1 < -0.5)
        // {
        //   updateStopLoss(bid - getCurrentSpread());
        // }

        // if(pdir < 0.0) // || pind < 0.0  || trend < 0.0
        // {
        //   // closePosition();
        //   updateStopLoss(bid - getCurrentSpread());
        //   return;
        // }

        if(sig0 > 0.5 && _needAveraging && profit <= 0.0
          && (_entryPrice-getCurrentPrice())> _averagingCount*_volatility/5.0) {
          // We need to check if we are far away enough from the entry price:
          // Perform dollar cost averating:
          logDEBUG("Performing long pos averaging.")
          dollarCostAverage();
        }
      }
      else {
        if(sig0 > 0.5)
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


        // if(profit<0.0 && sig1 > 0.5)
        // {
        //   updateStopLoss(bid + getCurrentSpread());
        // }

        // if(pdir > 0.0) // || pind > 0.0 || trend > 0.0
        // {
        //   // closePosition();
        //   updateStopLoss(bid + getCurrentSpread());
        //   return;
        // }

        if(sig0 < -0.5 && _needAveraging && profit <= 0.0
          && (getCurrentPrice()-_entryPrice)> _averagingCount*_volatility/5.0) {
          // We need to check if we are far away enough from the entry price:
          // Perform dollar cost averating:
          logDEBUG("Performing short pos averaging.")
          dollarCostAverage();
        }        
      }

      // Check if we have a sub signal:
      if(getSubSignal())
      {
        logDEBUG(TimeCurrent() <<": performing dollar averaging for sub signal")
        dollarCostAverage();
      }

      if(!_inRecovery)
      {
        // check if we are loosing ourself:
        double oprice = getOpenPrice();

        if(isLong() && (oprice - bid) > _volatility)
        {
          logDEBUG("Entering recovery from long position.")
          // We have to close the current long position and 
          // apply edging for recovery:
          _inRecovery = true;
          _zoneWidth = oprice-bid;
          _totalLost = getPositionVolume()*(_zoneWidth);
          _zoneHigh = oprice;
          _zoneLow = bid;
          _targetProfit = _zoneWidth;
          toggleHedge(latest_price.bid);
        }
        else if(isShort() && (bid - oprice) > _volatility)
        {
          // We should enter a long position now:
          logDEBUG("Entering recovery from short position.")
          _inRecovery = true;
          _zoneWidth = latest_price.ask-oprice;
          _totalLost = getPositionVolume()*(_zoneWidth);
          _zoneHigh = latest_price.ask;
          _zoneLow = oprice;
          _targetProfit = _zoneWidth;
          toggleHedge(latest_price.ask);
        }
      }
    }
    else {
      // Retrieve raw volatility:
      double vol = getVolatility();
      
      // logDEBUG(TimeCurrent() << ": Checking new position, pdir="<<pdir<<", trend="<<trend<<", pind="<<pind<<", sig="<<sig<<", vol="<<vol)

      // We use the current volatility value to define the value
      // that we can put at risk:

      // Check if we should buy or sell:
      if(pdir>0.0 && trend>0.0 && pind>0.0 && sig0>0.0 && sig1>0.0)
         // && level>_volatilityThreshold)
      {
        // In that case we should place a buy order,
        double conf = computeNormalizedConfidence(pdir*trend*pind*sig0);
        logDEBUG(TimeCurrent() << ": Should open long position with pdir="<<pdir<<", trend="<<trend<<", pind="<<pind<<", sig0="<<sig0<<", vol="<<vol<<", conf="<<conf)
        openPosition(ORDER_TYPE_BUY,vol,1.0); //conf);
      }

      if(pdir<0.0 && trend<0.0 && pind<0.0 && sig0<0.0 && sig1<0.0) 
         // && level>_volatilityThreshold)
      {
        double conf = computeNormalizedConfidence(pdir*trend*pind*sig0);
        logDEBUG(TimeCurrent() << ": Should open short position with pdir="<<pdir<<", trend="<<trend<<", pind="<<pind<<", sig0="<<sig0<<", vol="<<vol<<", conf="<<conf)
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
    _entryTime = TimeCurrent();
    _sigLevel = 0;
    _prevProfit = 0.0;
    _inRecovery = false;
    _totalLost = 0.0;
    _bounceCount = 0;

    logDEBUG(TimeCurrent() << ": Entry price: " << _entryPrice)

    // reset averaging count:
    _averagingCount = 1;

    sendDealOrder(_security, otype, _lotSize, 0.0, 0.0, 0.0);

    // Assign the absolute stoploss:
    // double oprice = getOpenPrice();
    // updateSLTP(_security,oprice + (isLong() ? (-_volatility) : _volatility));
    
    // logDEBUG(TimeCurrent() << ": Updated stoploss to " << getStopLoss() << " for sub step "<<_averagingCount)
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
    // double oprice = getOpenPrice();
    // updateSLTP(_security,oprice + (isLong() ? (-_volatility) : _volatility));

    // logDEBUG(TimeCurrent() << ": Updated stoploss to " << getStopLoss() << " for sub step "<<_averagingCount)
  }
  
  virtual void onTick()
  {

  }

};
