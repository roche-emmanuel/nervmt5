#include <nerv/core.mqh>

#include <nerv/rnn/SecurityTrader.mqh>

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
    nvSecurityTrader* trader = addTrader("EURUSD",0.5);
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
  nvSecurityTrader* addTrader(string symbol, double entry)
  {
    nvSecurityTrader* trader = new nvSecurityTrader(symbol,entry);
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
