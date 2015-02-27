
#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include <nerv/trades.mqh>
#include "RRLModelTraits.mqh"
#include "RRLTrainTraits.mqh"

struct nvRRLOnlineTrainingContext
{
  nvVecd dFt_1;
  nvVecd dFt;
  nvVecd dRt;
  nvVecd dDt;
  nvVecd params;

  double Ft_1;
  double A;
  double B;
};

/* Base class used to represent an RRL trading model. */
class nvRRLModel : public nvTradeModel
{
private:
  nvRRLModelTraits *_traits;

  nvVecd _batchTrainReturns;
  nvVecd _onlineTrainReturns;
  nvVecd _evalReturns;
  nvVecd _lastReturns;

  nvVecd _theta;
  
  double _currentSignal;
  double _returnMean;
  double _returnDev;
  double _wealth;

  bool _batchTrainNeeded;

  nvRRLOnlineTrainingContext _onlineContext;

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
  /* Method used to build the prediction from a parameter vector and the 
  current theta vector. */
  virtual double predict(const nvVecd& params, const nvVecd& theta);

  /* Method used to get a prediction using the current context and
   the newly provided inputs. This call will also provide a confidence value.
   The confidence will always be between 0.0 and 1.0. */
  virtual double predict(const nvVecd &rvec, double &confidence);

  /* Method used to train the model when applicable. */
  virtual void train(const nvRRLTrainTraits &trainTraits);

  /* Add a price return to the list of trailing returns. */
  virtual void addPriceReturn(double rt);

  /* perform online training. */
  virtual void performOnlineTraining(nvRRLOnlineTrainingContext& ctx);

  /* perform batch training. */
  virtual void performBatchTraining();

  /* evaluate the current sample. */
  virtual double evaluate(double &confidence);

  /* Retrieve the current (or latest) signal emitted by this model. */
  virtual double getCurrentSignal() const;

  /* Initialize the online training context. */
  virtual void initOnlineContext(nvRRLOnlineTrainingContext& context);

  /* Ensure that the norm of the theta vector is not becoming too big. */
  virtual void validateThetaNorm();
};


///////////////////////////////// implementation part ///////////////////////////////


nvRRLModel::nvRRLModel(nvRRLModelTraits *traits)
  : _traits(NULL),
    _currentSignal(0.0),
    _returnMean(0.0),
    _returnDev(0.0),
    _wealth(0.0),
    _batchTrainNeeded(true),
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
  int rlen = _traits.returnsMeanLength();

  CHECK(ni > 0, "Invalid number of input returns.");
  CHECK(rlen > 0, "Invalid number of returns for mean computation.");
  CHECK(blen >= 0 || olen >= 0, "Invalid training settings.");

  _theta.resize(ni + 2, 1.0);
  _batchTrainReturns.resize(MathMax(blen, 0));
  _onlineTrainReturns.resize(MathMax(olen, 0));
  _evalReturns.resize(ni);
  _lastReturns.resize(rlen);
}

void nvRRLModel::reset()
{
  logDEBUG("Resetting RRLModel.")
  initOnlineContext(_onlineContext);
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

  // Default value for confidence:
  double confidence = 0.0;
  double signal = 0.0;

  // Retrieve the previous signal before we override it:
  double Ft_1 = getCurrentSignal();

  // Add the return price to the trailing vectors:
  addPriceReturn(rt);

  long bcount = dt.barCount();

  bool ready = true;

  if (bcount < _traits.batchTrainLength())
  {
    // We don't have enough bars to perform the initial batch training.
    ready = false;
  }

  if (bcount < _traits.onlineTrainLength())
  {
    // We don't have enough bars to perform the online training.
    ready = false;
  }

  if (bcount < _traits.returnsMeanLength())
  {
    // We don't have enough bars to compute the returns mean and deviation.
    ready = false;
  }

  if (ready) {
    if(_traits.batchTrainLength() >= 0 && _batchTrainNeeded) 
    {
      logDEBUG("Performing batch training at bcount=" << bcount);
      _batchTrainNeeded = false;
      performBatchTraining();
    }

    if (_traits.onlineTrainLength() >= 0)
    {
      // perform the online training.
      // logDEBUG("Performing online training at bcount=" << bcount);
      performOnlineTraining(_onlineContext);
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
    _history.add("close_prices", price);
    _history.add("price_returns", rt);
    _history.add("signals", signal);
    _history.add("confidence", confidence);

    // Compute the return mean and deviation:
    _history.add("return_mean", _returnMean);
    _history.add("return_dev", _returnDev);

    // Also compute the theoritical return:
    double Ft = getCurrentSignal();
    double tcost = _traits.transactionCost();
    double Rt = Ft_1 * rt - tcost * MathAbs(Ft - Ft_1); 
    _history.add("theoretical_returns", Rt);

    // And compute the total wealth:
    _wealth += Rt;
    _history.add("theoretical_wealth", _wealth);

    // Also write the expoential moving average version of the sharpe ratio:
    double eSR = 0.0;
    double A = _onlineContext.A;
    double B = _onlineContext.B;
    if(B - A*A != 0.0) {
      eSR = A/MathSqrt(B-A*A);
    }
    _history.add("ema_SR",eSR);

    // Also write the norm of the theta vector:
    _history.add("theta_norm",_theta.norm());
  }

  return ready;
}

double nvRRLModel::predict(const nvVecd& params, const nvVecd& theta)
{
  double val = theta * params;
  return nv_tanh(val);  
}

double nvRRLModel::predict(const nvVecd &rvec, double &confidence)
{
  double Ft_1 = getCurrentSignal();
  // logDEBUG("Previous signal is : " << Ft_1);

  confidence = 1.0;
  nvVecd params(rvec.size() + 2);

  params.set(0, 1.0);
  params.set(1, Ft_1);
  params.set(2, (rvec - _returnMean) / _returnDev);

  return predict(params,_theta);
}

void nvRRLModel::addPriceReturn(double rt)
{
  if (_traits.batchTrainLength() >= 0) {
    _batchTrainReturns.push_back(rt);
  }

  if (_traits.onlineTrainLength() >= 0) {
    _onlineTrainReturns.push_back(rt);
  }

  _evalReturns.push_back(rt);
  _lastReturns.push_back(rt);

  // We can compute the returns mean and deviation right here:
  _returnMean = _lastReturns.mean();
  _returnDev = _lastReturns.deviation();
}

void nvRRLModel::performOnlineTraining(nvRRLOnlineTrainingContext& ctx)
{
  // For now we just use the current return vector to perform the training.
  double A = ctx.A;
  double B = ctx.B;
  double Ft_1 = getCurrentSignal();

  ctx.params.set(0, 1.0);
  ctx.params.set(1, Ft_1);
  ctx.params.set(2, (_evalReturns - _returnMean) / _returnDev);

  double rt = _evalReturns.back();

  double Ft = predict(ctx.params,_theta);
  double tcost = _traits.transactionCost();
  double Rt = Ft_1 * rt - tcost * MathAbs(Ft - Ft_1);    

  if(B-A*A != 0.0) {
    // We can perform the training.
    // 1. Compute the new value of dFt/dw
    ctx.dFt = (ctx.params + ctx.dFt_1 * _theta[1])*(1 - Ft*Ft);

    // 2. compute dRt/dw
    double dsign = tcost * nv_sign(Ft - Ft_1);
    ctx.dRt = ctx.dFt_1 * (rt + dsign) - ctx.dFt * dsign; 

    // 3. compute dDt/dw
    ctx.dDt = ctx.dRt * (B - A * Rt)/MathPow(B - A*A,1.5);

    // 4. update Theta vector:
    double learningRate = 0.01; // TODO: provide as trait.
    _theta += ctx.dDt * learningRate;

    //logDEBUG("New theta norm: "<< _theta.norm());
    
    // Validate the norm of the theta vector:
    validateThetaNorm();

	  // Advance one step:
	  ctx.dFt_1 = ctx.dFt;    
  }

  // The previous computation might have updated the value of Ft
  // So we might want to recompute Ft and Rt here.

  // Use Rt to update A and B:
  double adapt = 0.01; // TODO: Provide as trait.
  ctx.A = A + adapt * (Rt - A);
  ctx.B = B + adapt * (Rt*Rt - B);
}

void nvRRLModel::performBatchTraining()
{

}

double nvRRLModel::evaluate(double &confidence)
{
  _currentSignal = predict(_evalReturns, confidence);
  return _currentSignal;
}

double nvRRLModel::getCurrentSignal() const
{
  return _currentSignal;
}

void nvRRLModel::initOnlineContext(nvRRLOnlineTrainingContext& context)
{
  logDEBUG("Initializing online training context");
  context.A = 0.0;
  context.B = 0.0;
  context.dFt_1.resize(_theta.size());
  context.params.resize(_theta.size());
}

void nvRRLModel::validateThetaNorm()
{
  double tn = _theta.norm();
  double maxNorm = 5.0;
  if(tn>maxNorm) {
    _theta *= exp(-tn/maxNorm + 1);
  }
}
