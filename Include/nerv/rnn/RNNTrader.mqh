#include <nerv/core.mqh>

#include <nerv/rnn/SecurityTrader.mqh>

/*
Class: nvRNNTrader

Base class representing a trader 
*/
class nvRNNTrader : public nvObject
{
protected:
  nvSecurityTrader* _traders[];

public:
  /*
    Class constructor.
  */
  nvRNNTrader()
  {
    logDEBUG("Creating new RNN Trader")
    nvSecurityTrader* trader = addTrader("EURUSD",0.5);
    
    // input symbols should be specified before adding the predictors:
    string inputs[] = {"AUDUSD","GBPUSD","NZDUSD","USDCAD","USDCHF","USDJPY"};
    trader.addInputSymbols(inputs);

    // trader.addPredictor("eval_results_v36.csv");
    // trader.addPredictor("eval_results_v36b.csv");
    // trader.addPredictor("eval_results_v36c.csv");
    // trader.addPredictor("eval_results_v38.csv");
    // trader.addPredictor("eval_results_v38b.csv");
    // trader.addPredictor("eval_results_v38c.csv");

    trader.addPredictor("eval_results_v42.csv");
    // trader.addPredictor("eval_results_v42b.csv");
    // trader.addPredictor("eval_results_v42c.csv");
    trader.addPredictor("eval_results_v42d.csv");
    // trader.addPredictor("eval_results_v42e.csv");

    trader.addPredictor("eval_results_v44.csv");
    trader.addPredictor("eval_results_v44d.csv");

    // trader.addRemotePredictor("tcp://192.168.0.20:30000");

    // trader = addTrader("USDJPY",0.4);
    // trader.addPredictor("eval_results_v37.csv");
    // trader.addPredictor("eval_results_v37b.csv");
    // trader.addPredictor("eval_results_v37c.csv");
  }

  /*
    Copy constructor
  */
  nvRNNTrader(const nvRNNTrader& rhs)
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
