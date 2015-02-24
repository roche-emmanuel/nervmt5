
#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include "RRLModelTraits.mqh"
#include "RRLTrainTraits.mqh"
#include "RRLDigestTraits.mqh"
#include "HistoryMap.mqh"

/* Base class used to represent an RRL trading model. */
class nvRRLModel : public nvObject
{
protected:
  nvRRLModelTraits _traits;

  /* A model can keep an history of relevant data. */
  nvHistoryMap _history;

public:
  /* Default constructor. Will assign the model traits. */
  nvRRLModel(const nvRRLModelTraits &traits);

  /* Assign the model traits. */
  void setTraits(const nvRRLModelTraits &traits);

  /* Reset the state of this model so that the next digest cycle will
    restart from scratches. */
  void reset();

  /* Public method used to provide a new input to the model,
    And retrieve a new prediction. This method will also output a
    confidence value computed from the predict method. */
  double digest(const nvRRLDigestTraits &dt, double &confidence);

protected:
  /* Method used to get a prediction using the current context and
   the newly provided inputs. This call will also provide a confidence value.
   The confidence will always be between 0.0 and 1.0. */
  virtual double predict(const nvVecd &rvec, double &confidence);

  /* Method used to train the model when applicable. */
  virtual void train(const nvRRLTrainTraits &trainTraits);
};


///////////////////////////////// implementation part ///////////////////////////////


nvRRLModel::nvRRLModel(const nvRRLModelTraits &traits)
{
  // Assign the traits:
  setTraits(traits);
}

void nvRRLModel::setTraits(const nvRRLModelTraits &traits)
{
  _traits = traits;

  _history.setPrefix(_traits.id()=="" ? "" : (_traits.id()+"_"));

  if (_traits.historyLength() != _history.getSize())
  {
    // Need to reset the history:
    _history.setSize(_traits.historyLength());
    _history.clear();
  }
}

void nvRRLModel::reset()
{

}

double nvRRLModel::digest(const nvRRLDigestTraits &dt, double &confidence)
{
  // Default value for confidence:
  confidence = 0.0;

  if (dt.isFirst()) {
    logDEBUG("Received first digest element, reseting RRLModel.");
    reset();
    return 0.0;
  }

  // This is not the first element so we should process it.
  double price = dt.closePrice();
  double rt = dt.priceReturn();

  // But first we should add the inputs to the history if requested.
  if (_traits.keepHistory()) {
    _history.add("close_prices", price);
    _history.add("price_returns", rt);
  }

  double signal = 0.0;
  // TODO: provide implementation to predict the signal and the confidence.

  // Write the history data if requested:
  if (_traits.keepHistory()) {
    _history.add("signals",signal);
    _history.add("confidence",confidence);
  }

  return signal;
}

double nvRRLModel::predict(const nvVecd &rvec, double &confidence)
{
  // TODO: provide implementation.
  return 0.0;
}

void nvRRLModel::train(const nvRRLTrainTraits &trainTraits)
{
  // TODO: provide implementation.
}
