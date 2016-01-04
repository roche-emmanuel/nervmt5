#include <nerv/core.mqh>

#include <nerv/rnn/SecurityTrader.mqh>

/*
Class: nvRNNTrader

Base class representing a trader 
*/
class nvRNNTrader : public nvObject
{
protected:
  nvSecurityTrader* _trader;

public:
  /*
    Class constructor.
  */
  nvRNNTrader()
  {
    logDEBUG("Creating new RNN Trader")
    _trader = new nvSecurityTrader("EURUSD");
    _trader.addPredictor("eval_results_v36.csv");
    _trader.addPredictor("eval_results_v36b.csv");
  }

  /*
    Copy constructor
  */
  nvRNNTrader(const nvRNNTrader& rhs) : _trader(NULL)
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
    RELEASE_PTR(_trader);
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
    _trader.onTick();
  }
};
