#include <nerv/core.mqh>

#include <nerv/rnn/SecurityTrader.mqh>

/*
Class: nvRNNTrader

Base class representing a trader 
*/
class nvRNNTrader : public nvObject
{
protected:
  nvSecurityTrader _trader;

public:
  /*
    Class constructor.
  */
  nvRNNTrader()
    : _trader("EURUSD")
  {
    logDEBUG("Creating new RNN Trader")
  }

  /*
    Copy constructor
  */
  nvRNNTrader(const nvRNNTrader& rhs) : _trader("")
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvRNNTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvRNNTrader()
  {
    logDEBUG("Deleting RNNTrader")
  }

  /*
  Function: update
  
  Method called to update the state of this trader 
  normally once per minute
  */
  void update(datetime ctime)
  {
    _trader.update(ctime);
  }

  void onTick()
  {
    // Should handle onTick  here.
  }
};
