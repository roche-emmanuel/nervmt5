#include <nerv/core.mqh>

#include <nerv/trading/SecurityTrader.mqh>
#include <nerv/trading/RandomTrader.mqh>

/*
Class: nvMultiTrader

Base class representing a trader 
*/
class nvMultiTrader : public nvObject
{
protected:
  nvSecurityTrader* _traders[];

public:
  /*
    Class constructor.
  */
  nvMultiTrader()
  {
    logDEBUG("Creating new RNN Trader")
    // nvSecurityTrader* trader = new nvSecurityTrader("EURUSD");
    nvSecurityTrader* trader = new nvRandomTrader("EURUSD");
    addTrader(trader);
  }

  /*
    Copy constructor
  */
  nvMultiTrader(const nvMultiTrader& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvMultiTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvMultiTrader()
  {
    logDEBUG("Deleting MultiTrader")
    int len = ArraySize(_traders);
    for(int i=0;i<len;++i)
    {
      RELEASE_PTR(_traders[i]);  
    }
    ArrayResize( _traders, 0 );
  }

  /*
  Function: addTrader
  
  Method to add a security trader
  */
  nvSecurityTrader* addTrader(nvSecurityTrader* trader)
  {
    nvAppendArrayElement(_traders,trader);
    return trader;
  }
  
  /*
  Function: update
  
  Method called to update the state of this trader 
  normally once per minute
  */
  void update(datetime ctime)
  {
    int len = ArraySize( _traders );
    for(int i = 0;i<len;++i)
    {
      _traders[i].update(ctime);  
    }
  }

  void onTick()
  {
    // Should handle onTick  here.
    int len = ArraySize( _traders );
    for(int i = 0;i<len;++i)
    {
      _traders[i].onTick();  
    }
  }
};
