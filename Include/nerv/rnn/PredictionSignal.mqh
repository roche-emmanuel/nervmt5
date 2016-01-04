
#include <nerv/core.mqh>

/*
Class: nvPredictionSignal

Class used to encapsulate a prediction signal from a given source
*/
class nvPredictionSignal : public nvObject
{
public:
  /*
    Class constructor.
  */
  nvPredictionSignal()
  {
    // No op.
  }

  /*
    Copy constructor
  */
  nvPredictionSignal(const nvPredictionSignal& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvPredictionSignal& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvPredictionSignal()
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
    // TODO: Provide implementation
    THROW("No implementation");
    return 0.0;
  }
  
};
