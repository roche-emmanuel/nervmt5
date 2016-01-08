#include <nerv/core.mqh>

#include <nerv/trading/SecurityTrader.mqh>

/*
Class: nvRandomTrader

Base class representing a trader 
*/
class nvRandomTrader : public nvSecurityTrader
{
protected:
  // Random generator:
  SimpleRNG rnd;

public:
  /*
    Class constructor.
  */
  nvRandomTrader(string symbol)
    :nvSecurityTrader(symbol)
  {
    // rnd.SetSeedFromSystemTime();
    rnd.SetSeed(123);
  }

  /*
    Copy constructor
  */
  nvRandomTrader(const nvRandomTrader& rhs) : nvSecurityTrader("")
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvRandomTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvRandomTrader()
  {
    logDEBUG("Deleting SecurityTrader")
  }
  
  virtual double getSignal(datetime ctime)
  {
    double pred = (rnd.GetUniform()-0.5)*2.0;
    logDEBUG(TimeCurrent() <<": signal = "<<pred);
    
    pred = pred>0.0 ? 1.0 : -1.0;
    return pred;
  }

  virtual void checkPosition()
  {
    if(!hasPosition(_security))
      return; // nothing to do.

    // We close the position if the equity becomes too low:
    double eq = nvGetEquity();
    double balance = nvGetBalance();
    if(eq/balance < 0.94) {
      closePosition(_security);
    }
  }
};
