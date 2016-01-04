
#include <nerv/core.mqh>
#include <nerv/utils.mqh>
#include <nerv/rnn/PredictionSignal.mqh>

/*
Class: nvRemoteSignal

Class used to encapsulate a prediction signal from a given file
*/
class nvRemoteSignal : public nvPredictionSignal
{
protected:
  // List of input symbol to use as inputs:
  string _inputs[];

  // last update time:
  datetime _lastUpdateTime;

public:
  /*
    Class constructor.
  */
  nvRemoteSignal(string address, string & inputs[])
  {
    int len = ArraySize( inputs );
    for(int i=0;i<len;++i)
    {
      nvAppendArrayElement(_inputs,inputs[i]);
    }

    _lastUpdateTime = 0;
    
    logDEBUG("Should connect to address: " << address)
  }

  /*
    Copy constructor
  */
  nvRemoteSignal(const nvRemoteSignal& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvRemoteSignal& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvRemoteSignal()
  {
    // No op.
  }

  /*
  Function: getPrediction
  
  Return a prediction in the range (-1,1) or 0 if we are not 
  predicting anything for the requested date:
  */
  virtual double getPrediction(datetime time)
  {
    return 0.0;
  }
  
};
