
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
  
  nvVecd _batchTrainReturns;
  nvVecd _onlineTrainReturns;
  nvVecd _evalReturns;

  nvVecd _theta;
  double _currentSignal;
  double _returnMean;
  double _returnMean2;

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

  /* Add a price return to the list of trailing returns. */
  virtual void addPriceReturn(double rt);

  /* perform online training. */
  virtual void performOnlineTraining();

  /* perform batch training. */
  virtual void performBatchTraining();  

  /* evaluate the current sample. */
  virtual double evaluate(double& confidence);

  /* Retrieve the current (or latest) signal emitted by this model. */
  virtual double getCurrentSignal() const;
};


///////////////////////////////// implementation part ///////////////////////////////


nvRRLModel::nvRRLModel(nvRRLModelTraits *traits)
  : _traits(NULL),
    _currentSignal(0.0),
    _returnMean(0.0),
    _returnMean2(1.0),
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

  int ni = _traits.numInputReturns();
  int blen = _traits.batchTrainLength();
  int olen = _traits.onlineTrainLength();

  CHECK(ni>0,"Invalid number of input returns.");
  CHECK(blen>=0 || olen>=0,"Invalid training settings.");

  _theta.resize(ni+2,1.0);
  _batchTrainReturns.resize(MathMax(blen,0));
  _onlineTrainReturns.resize(MathMax(olen,0));
  _evalReturns.resize(ni);
}

void nvRRLModel::reset()
{

}

bool nvRRLModel::digest(const nvDigestTraits &dt, nvTradePrediction &pred)
{
  // mark the prediction as invalid by default:
  pred.valid(false);

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

  // Add the return price to the trailing vectors:
  addPriceReturn(rt);

  long bcount = dt.barCount();

  bool ready = true;

  if(bcount<_traits.batchTrainLength())
  {
    // We don't have enough bars to perform the initial batch training.
    ready = false;
  }

  if(bcount<_traits.onlineTrainLength())
  {
    // We don't have enough bars to perform the online training.
    ready = false;
  }

  if(bcount==_traits.batchTrainLength())
  {
    logDEBUG("Performing batch training at bcount="<<bcount);
    performBatchTraining();
  }

  if(ready) {
    if(_traits.onlineTrainLength() >= 0)
    {
      // perform the online training.
      logDEBUG("Performing online training at bcount="<<bcount);
      performOnlineTraining();
    }

    // perform the evaluation:
    signal = evaluate(confidence);

    // write the data into the prediction and mark it as valid:
    pred.valid(true);
    pred.signal(signal);
    pred.confidence(confidence);    
  }

  // Write the history data if requested:
  if (_traits.keepHistory()) {
    _history.add("signals", signal);
    _history.add("confidence", confidence);
  }

  return ready;
}

double nvRRLModel::predict(const nvVecd &rvec, double &confidence)
{
  double Ft_1 = getCurrentSignal();
  logDEBUG("Previous signal is : " << Ft_1);

  confidence = 1.0;
  nvVecd params(rvec.size()+2);

  // Compute the current deviation for the mean and mean2 values:
  double rmean = _returnMean;
  double rdev = MathSqrt(_returnMean2 - _returnMean*_returnMean);

  params.set(0, 1.0);
  params.set(1, Ft_1);
  params.set(2, (rvec - rmean) / rdev);

  double val = _theta * params;
  return nv_tanh(val);
}

void nvRRLModel::train(const nvRRLTrainTraits &trainTraits)
{
  // TODO: provide implementation.
}

void nvRRLModel::addPriceReturn(double rt)
{
  if (_traits.batchTrainLength() >= 0) {
    _batchTrainReturns.push_back(rt);
  }

  if(_traits.onlineTrainLength() >= 0) {
    _onlineTrainReturns.push_back(rt);
  }

  _evalReturns.push_back(rt);

  // This method should also update the return mean and deviation exponential moving averages:
  double eps = 0.0001;
  _returnMean = _returnMean + eps * (rt - _returnMean);
  _returnMean2 = _returnMean2 + eps * (rt*rt - _returnMean2);
}

void nvRRLModel::performOnlineTraining()
{
  
}

void nvRRLModel::performBatchTraining()
{

}

double nvRRLModel::evaluate(double& confidence)
{
  return predict(_evalReturns, confidence);
}

double nvRRLModel::getCurrentSignal() const
{
  return _currentSignal;
}