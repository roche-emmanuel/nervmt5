#include <nerv/core.mqh>
#include <nerv/trading/SecurityTrader.mqh>
#include <nerv/math/SimpleRNG.mqh>

/*
Class: nvRandomTrader

Base class representing a trader 
*/
class nvRandomTrader : public nvSecurityTrader {
protected:
  // Random generator:
  SimpleRNG rnd;
  datetime _lastTime;
  int _delay;

public:
  /*
    Class constructor.
  */
  nvRandomTrader(string symbol)
    : nvSecurityTrader(symbol)
  {
    logDEBUG("Creating RandomTrader")
    
    // rnd.SetSeedFromSystemTime();
    rnd.SetSeed(123);

    _lastTime = 0;
    _delay = (int)(120 + 3600*rnd.GetUniform());
  }

  /*
    Class destructor.
  */
  ~nvRandomTrader()
  {
    logDEBUG("Deleting RandomTrader")
  }

  virtual void update(datetime ctime)
  {

  }
  
  virtual void onTick()
  {
    datetime ctime = TimeCurrent();
    if((ctime-_lastTime)<_delay)
      return;

    _delay = (int)(120 + 3600*rnd.GetUniform());
    _lastTime = ctime;

    // Close th current position if any:
    if(hasPosition())
    {
      closePosition();
    }

    // if we are not in a position, we open a new one randomly:
    int otype = (rnd.GetUniform()-0.5) > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    openPosition(otype,0.01);
  }
};
