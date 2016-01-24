#include <nerv/core.mqh>
#include <nerv/trading/SecurityTrader.mqh>
#include <nerv/trading/HASignal.mqh>

/*
Class: nvHATrader

Base class representing a trader 
*/
class nvHATrader : public nvSecurityTrader {
protected:
  nvHASignal* _HA;

  double _lastDir;

public:
  /*
    Class constructor.
  */
  nvHATrader(string symbol, ENUM_TIMEFRAMES period = PERIOD_H4)
    : nvSecurityTrader(symbol)
  {
    logDEBUG("Creating HATrader")
    _HA = new nvHASignal(symbol,period);
    _lastDir = 0.0;
  }

  /*
    Class destructor.
  */
  ~nvHATrader()
  {
    logDEBUG("Deleting HATrader")
    RELEASE_PTR(_HA);
  }

  virtual void update(datetime ctime)
  {

  }
  
  virtual void onTick()
  {
    double newDir = _HA.getSignal();

    // Close th current position if needed:
    if(hasPosition() && _lastDir*newDir < 0.0)
    {
      closePosition();
      _lastDir = 0.0;
    }

    if(!hasPosition() && newDir!=0.0)
    {
      // if we are not in a position, we open a new one randomly:
      int otype = newDir > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      openPosition(otype,0.01);      
      _lastDir = newDir;
    }
  }
};
