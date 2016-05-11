#include <nerv/core.mqh>
#include <nerv/utils.mqh>
#include <nerv/core/Object.mqh>

/*
Class: nvSecurityTrader

Base class representing a trader 
*/
class nvSecurityTrader : public nvObject
{
protected:
  string _symbol;
  ENUM_TIMEFRAMES _period;

  double _psize;

  double _riskLevel;
  double _traderWeight;

  /** Used for the bar handling mechanism. */
  datetime _last_bar_time;

public:
  /*
    Class constructor.
  */
  nvSecurityTrader(string symbol, ENUM_TIMEFRAMES period = PERIOD_CURRENT)
  {
    logDEBUG("Creating Security Trader for "<<symbol)

    _symbol = symbol;
    _period = period==PERIOD_CURRENT ? Period() : period;
    
    _psize = nvGetPointSize(_symbol);
    
    _riskLevel = 0.02;
    _traderWeight = 1.0;

    // Save the time of the current bar so that we can start detecting new bars afterwards:
    datetime curTime[1];
    CHECK(CopyTime(_symbol, _period, 0, 1, curTime) == 1, "Cannot retrieve the time of the last bar");
    _last_bar_time = curTime[0];
  }

  /*
    Copy constructor
  */
  nvSecurityTrader(const nvSecurityTrader& rhs)
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

  int openPosition(int otype, double lot, double sl = 0.0, 
    double tp = 0.0, double price = 0.0)
  {
    return nvOpenPosition(_symbol,otype,lot,sl,tp,price);
  }

  void setRiskLevel(double risk)
  {
    _riskLevel = risk;
  }

  bool closePosition()
  {
    return nvClosePosition(_symbol);
  }

  bool hasPosition()
  {
    return PositionSelect(_symbol);
  }
  
  bool isLong()
  {
    if(hasPosition())
    {
      return PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
    }
    return false;
  }

  bool isShort()
  {
    if(hasPosition())
    {
      return PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL;
    }
    return false;
  }

  /*
  Function: evaluateLotSize
  
  Main method of this class used to evaluate the lot size that should be used for a potential trade.
  */
  double evaluateLotSize(double numLostPoints, double confidence)
  {
    return nvEvaluateLotSize(_symbol, numLostPoints, _riskLevel, _traderWeight, confidence);
  }

  /*
  Function: update
  
  Method called to update the state of this trader 
  normally once every fixed time delay.
  */
  virtual void update(datetime ctime)
  {

  }
  
  /**
  Function: onBar

  Method called when a new bar is produced in the given period.
  */
  virtual void handleBar()
  {

  }

  /**
  Function handleTick

  Method called to handle a tick event.
  */
  virtual void handleTick()
  {

  }

  virtual void onTick()
  {
    datetime curTime[1];

    // copying the last bar time to the element New_Time[0]
    CHECK(CopyTime(_symbol, _period, 0, 1, curTime) == 1, "Cannot retrieve the time of the last bar");

    if (_last_bar_time != curTime[0])
    {
      CHECK(curTime[0] > _last_bar_time, "Going back in time " << curTime[0] << "<" << _last_bar_time);

      ulong diff = curTime[0] - _last_bar_time;
      _last_bar_time = curTime[0];

      // Ensure the time delta is correct:
      ulong tdelta = nvGetPeriodDuration(_period);
      CHECK(diff % tdelta == 0, "Unexpected bar delta difference, diff=" << diff << " bar duration: " << tdelta);

      handleBar();    
    }

    // We call the handleTick() method afterward:
    handleTick(); 
  }
};
