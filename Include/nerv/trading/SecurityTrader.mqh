#include <nerv/core.mqh>

#include <nerv/trading/TraderBase.mqh>
#include <nerv/math.mqh>
#include <nerv/math/SimpleRNG.mqh>
#include <nerv/utils.mqh>

/*
Class: nvSecurityTrader

Base class representing a trader 
*/
class nvSecurityTrader : public nvTraderBase
{
protected:
  // Last update time value, used to keep track
  // of the last time this trader was updated, to avoid double updates.
  datetime _lastUpdateTime;

  nvSecurity _security;

  // Current value of the entry signal:
  double _lastEntrySignal;

  // Level of risk:
  double _riskLevel;

  // open price of the current position if any.
  double _openPrice;

  // True if current position is a buy:
  bool _isBuy;

  double _entryThreshold;

  string _symbol;

  double _traderWeight;

public:
  /*
    Class constructor.
  */
  nvSecurityTrader(string symbol)
    : _security(symbol)
  {
    logDEBUG("Creating Security Trader for "<<symbol)

    _symbol = symbol;
    
    // Initialize the last update time:
    _lastUpdateTime = 0;

    // Last value of the entry signal:
    _lastEntrySignal = 0.0;

    // 1% of risk:
    _riskLevel = 0.01;

    _entryThreshold = 0.5;

    _traderWeight = 1.0;
  }

  /*
    Copy constructor
  */
  nvSecurityTrader(const nvSecurityTrader& rhs) : _security("")
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvSecurityTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvSecurityTrader()
  {
    logDEBUG("Deleting SecurityTrader")
  }
  
  virtual double getSignal(datetime ctime)
  {
    return 0.0;
  }

  /*
  Function: update
  
  Method called to update the state of this trader 
  normally once per minute
  */
  virtual void update(datetime ctime)
  {
    if(_lastUpdateTime>=ctime)
      return; // Nothing to process.

    _lastUpdateTime = ctime;
    // logDEBUG("Update cycle at: " << ctime << " = " << (int)ctime)

    // Retrieve the prediction signal at that time:
    // double pred = getPrediction(ctime);
    // double pred = (rnd.GetUniform()-0.5)*2.0;
    // pred = pred>0.0 ? 1.0 : -1.0;

    double pred = getSignal(ctime);

    // Check if we need to close the current position (if any)
    // if the new signal is not strong enough or if it is not
    // going in the same direction as the previous entry signal
    // we just close the position. Otherwise, we let it running
    // with the current trailing stop lost:
    // if(MathAbs(pred)<=_entryThreshold || pred *_lastEntrySignal <= 0.0)
    // {
    //   closePosition(_security);
    // }
      
    if(pred!=0.0 && !hasPosition(_security)) {
      openPosition(pred);
    }
  }

  /*
  Function: openPosition
  
  Method used to open a position given a signal value
  */
  void openPosition(double signal)
  {
    // we are not currently in a trade so we check if we should enter one:
    if(MathAbs(signal)<=_entryThreshold)
      return; // Should not enter anything.

    logDEBUG("Using prediction signal " << signal)

    // the prediction is good enough, so we place a trade:
    _lastEntrySignal = signal;
    
    string symbol = _security.getSymbol();

    // Get the current spread to define the number of lost points:
    double spread = nvGetSpread(symbol);

    // double lot = evaluateLotSize(spread*2.0,1.0,signal);
    double lot = evaluateLotSize(100,signal);
    // double lot = evaluateLotSize(100,1.0,signal > 0.0 ? 0.5 : -0.5);

    double sl = 0.0; //spread*nvGetPointSize(symbol);
    double tp = 0.0; //spread*nvGetPointSize(symbol);

    MqlTick last_tick;
    CHECK(SymbolInfoTick(symbol,last_tick),"Cannot retrieve last tick");
    
    _openPrice = signal > 0 ? last_tick.ask : last_tick.bid;
    _isBuy = signal > 0;

    // Send the order:
    int otype = signal>0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    sendDealOrder(_security, otype, lot, 0.0, sl, tp);
  }
  
  /*
  Function: evaluateLotSize
  
  Main method of this class used to evaluate the lot size that should be used for a potential trade.
  */
  double evaluateLotSize(double numLostPoints, double confidence)
  {
    return nvEvaluateLotSize(_security.getSymbol(), numLostPoints, _riskLevel, _traderWeight, confidence);
  }

  virtual void checkPosition()
  {
    // No op.
  }

  virtual double getTrailingOffset(MqlTick& last_tick)
  {
    return last_tick.ask - last_tick.bid;
  }

  // Check if we are in a long position:
  bool isLong()
  {
    if(hasPosition(_security))
    {
      return PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
    }

    return false;
  }

  /*
  Function: isShort
  
  Check if we are in  ashort position
  */
  bool isShort()
  {
    if(hasPosition(_security))
    {
      return PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL;
    }

    return false;    
  }
  
  /*
  Function: hasPosition
  
  Select the current position if any
  */
  bool hasPosition()
  {
    return hasPosition(_security);
  }
  
  /*
  Function: closePosition
  
  Close the current position if any
  */
  void closePosition()
  {
    closePosition(_security);
  }
  
  /*
  Function: getPositionProfit
  
  Retrieve the current profit for the current position if any.
  */
  double getPositionProfit()
  {
    if(hasPosition())
    {
      return PositionGetDouble(POSITION_PROFIT);
    }

    return 0.0;
  }
  
  /*
  Function: getStopLoss
  
  Retrieve the current stop loss value if any.
  */
  double getStopLoss()
  {
    if(hasPosition())
    {
      return PositionGetDouble(POSITION_SL);
    }
    return 0.0;
  }
  
  /*
  Function: getCurrentSpread
  
  Retrieve the current spread
  */
  double getCurrentSpread()
  {
    MqlTick last_tick;
    CHECK_RET(SymbolInfoTick(_symbol,last_tick),0.0,"Cannot retrieve last tick");
    return last_tick.ask - last_tick.bid;
  }
  
  /*
  Function: getCurrentPrice
  
  retrieve the current bid price
  */
  double getCurrentPrice()
  {
    MqlTick last_tick;
    CHECK_RET(SymbolInfoTick(_symbol,last_tick),0.0,"Cannot retrieve last tick");
    return last_tick.bid;    
  }

  /*
  Function: updateStopLoss
  
  Update the current stop loss value
  */
  void updateStopLoss(double nsl)
  {
    if(!hasPosition())
      return; // no current position.

    double sl = getStopLoss();
    if(sl==0.0) {
      updateSLTP(_security,nsl);
      return;
    }

    if(isLong() && nsl > sl) {
      updateSLTP(_security,nsl);
    }
    
    if(isShort() && nsl < sl)
    {
      updateSLTP(_security,nsl);
    }
  }
  
  /*
  Function: getOpenPrice
  
  Get the open price for the current position
  */
  double getOpenPrice()
  {
    if(hasPosition())
    {
      return PositionGetDouble(POSITION_PRICE_OPEN);
    }

    return 0.0;
  }
  
  /*
  Function: getPositionVolume
  
  Get the volume for the current position if any
  */
  double getPositionVolume()
  {
    if(hasPosition())
    {
      return PositionGetDouble(POSITION_VOLUME);
    }
    return 0.0;
  }
  
  virtual void onTick()
  {
    if(!hasPosition(_security))
      return; // nothing to do.

    checkPosition();

    if(!hasPosition(_security))
      return; // nothing to do.

    string symbol = _security.getSymbol();

    // We have an open position.
    // Get the current tick data:
    MqlTick last_tick;
    CHECK(SymbolInfoTick(symbol,last_tick),"Cannot retrieve last tick");

    double spread = last_tick.ask - last_tick.bid;

    double sl = PositionGetDouble(POSITION_SL);

    // Maximum number of lost spread:
    double maxLost = 10.0;
    double threshold = 0.0; //3*spread;
    double delta = getTrailingOffset(last_tick);

    if(delta<0.0)
      return; // Nothing to trail.
      
    if(_isBuy)
    {
      // We are in a long position:
      // secure the gain if the current values are high enough:
      double diff = last_tick.bid - _openPrice;
      double nsl = last_tick.bid - delta;
      if(diff>threshold && nsl>sl) {
        updateSLTP(_security,nsl);
      }
      // if(diff < -maxLost*spread) 
      // {
      //   closePosition(_security);
      // }
    }
    else {
      double diff = _openPrice - last_tick.ask;
      double nsl = last_tick.bid + delta;
      if(diff>threshold && (nsl<sl || sl==0.0)) {
        updateSLTP(_security,nsl);
      }
      // if(diff < -maxLost*spread) 
      // {
      //   closePosition(_security);
      // }
    }
  }
};
