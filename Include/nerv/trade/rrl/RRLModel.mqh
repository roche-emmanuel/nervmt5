
#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include <nerv/trades.mqh>
#include "RRLModelTraits.mqh"
#include "RRLTrainTraits.mqh"

/* Base class used to represent an RRL trading model. */
class nvRRLModel : public nvTradeModel
{
private:
  nvRRLModelTraits *_traits;

public:
  /* Default constructor. Will assign the model traits. */
  nvRRLModel(nvRRLModelTraits *traits = NULL);

  /* Traits reference constructor. This constructor will make a copy
  of the traits so that they can be assigned to this model. */
  nvRRLModel(const nvRRLModelTraits &traits);

  /* Assign the model traits. */
  virtual void setTraits(nvRRLModelTraits *traits);

  /* Reset the state of this model so that the next digest cycle will
    restart from scratches. */
  virtual void reset();

  /* Public method used to provide a new input to the model,
    And retrieve a new prediction. This method will also output a
    confidence value computed from the predict method. */
  virtual bool digest(const nvDigestTraits &dt, nvTradePrediction &pred);

protected:
  /* Method used to get a prediction using the current context and
   the newly provided inputs. This call will also provide a confidence value.
   The confidence will always be between 0.0 and 1.0. */
  virtual double predict(const nvVecd &rvec, double &confidence);

  /* Method used to train the model when applicable. */
  virtual void train(const nvRRLTrainTraits &trainTraits);
};


///////////////////////////////// implementation part ///////////////////////////////


nvRRLModel::nvRRLModel(nvRRLModelTraits *traits)
  : _traits(NULL),
    nvTradeModel(NULL)
{
  if (traits != NULL) {
    // Assign the traits:
    setTraits(traits);
  }
}

nvRRLModel::nvRRLModel(const nvRRLModelTraits &traits)
  : _traits(NULL),
    nvTradeModel(NULL)
{
  nvRRLModelTraits *copy = new nvRRLModelTraits(traits);
  setTraits(copy);
}

void nvRRLModel::setTraits(nvRRLModelTraits *traits)
{
  // call parent implementation:
  nvTradeModel::setTraits(traits);

  CHECK_PTR(traits, "Invalid traits.");

  RELEASE_PTR(_traits);
  _traits = traits;
}

void nvRRLModel::reset()
{

}

bool nvRRLModel::digest(const nvDigestTraits &dt, nvTradePrediction &pred)
{
  if (dt.isFirst()) {
    logDEBUG("Received first digest element, reseting RRLModel.");
    reset();
    return false;
  }

  // This is not the first element so we should process it.
  double price = dt.closePrice();
  double rt = dt.priceReturn();

  // But first we should add the inputs to the history if requested.
  if (_traits.keepHistory()) {
    _history.add("close_prices", price);
    _history.add("price_returns", rt);
  }

  // Default value for confidence:
  double confidence = 0.0;
  double signal = 0.0;
  // TODO: provide implementation to predict the signal and the confidence.

  // Write the history data if requested:
  if (_traits.keepHistory()) {
    _history.add("signals", signal);
    _history.add("confidence", confidence);
  }

  return true;
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
