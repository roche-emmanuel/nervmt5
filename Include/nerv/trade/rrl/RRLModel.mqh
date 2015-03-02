
#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include <nerv/trades.mqh>
#include "RRLModelTraits.mqh"
#include "RRLCostFunction_SR.mqh"

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

  nvRRLTrainContext_SR _context;

  nvRRLOnlineTrainingContext _onlineContext;
  int _evalCount;

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
  virtual double predict(const nvVecd &params, const nvVecd &theta);

  /* Method used to get a prediction using the current context and
   the newly provided inputs. This call will also provide a confidence value.
   The confidence will always be between 0.0 and 1.0. */
  virtual double predict(const nvVecd &rvec, double &confidence);

  /* Add a price return to the list of trailing returns. */
  virtual void addPriceReturn(double rt);

  /* perform online training. */
  virtual void performOnlineTraining(nvRRLOnlineTrainingContext &ctx);

  /* perform batch training. */
  virtual void performBatchTraining();

  /* evaluate the current sample. */
  virtual double evaluate(double &confidence);

  /* Retrieve the current (or latest) signal emitted by this model. */
  virtual double getCurrentSignal() const;

  /* Initialize the online training context. */
  virtual void initOnlineContext(nvRRLOnlineTrainingContext &context);

  /* Ensure that the norm of the theta vector is not becoming too big. */
  virtual void validateThetaNorm();

  /* Method used to compute the delta on the weights for a given sample. */
  void computeWeightDelta(nvRRLOnlineTrainingContext &ctx, const nvVecd &rvec, double Ft_1);

  /* Method used to perform a minimal simple batch training. */
  void performBatchTraining_simple();

  /* Method used to evaluate the performances on this model on a given return serie. */
  void evaluate(const nvVecd &returns, nvVecd &rets);
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

  _currentSignal = 0.0;
  _returnMean = 0.0;
  _returnDev = 0.0;
  _wealth = 0.0;
  _evalCount = 0;
  _batchTrainNeeded = true;

  int ni = _traits.numInputReturns();
  int blen = _traits.batchTrainLength();
  int olen = _traits.onlineTrainLength();
  int rlen = _traits.returnsMeanLength();
  int bf = _traits.batchTrainFrequency();

  // if bacth train frequency is set then we need a valid batch train length.
  CHECK(bf <= 0 || blen > 0, "Invalid batch train length for repeated training.");

  CHECK(ni > 0, "Invalid number of input returns.");
  CHECK(rlen > 0, "Invalid number of returns for mean computation.");
  CHECK(blen >= 0 || olen >= 0, "Invalid training settings.");

  CHECK(_traits.transactionCost() > 0, "Invalid transaction cost.");

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
    if (_traits.batchTrainLength() >= 0 && _batchTrainNeeded)
    {
      logDEBUG("Performing batch training at bcount=" << bcount);
      _batchTrainNeeded = false;
      performBatchTraining();
      _evalCount = 0;
    }

    if (_traits.onlineTrainLength() >= 0)
    {
      // perform the online training.
      logDEBUG("Performing online training at bcount=" << bcount);
      performOnlineTraining(_onlineContext);
    }

    // perform the evaluation:
    signal = evaluate(confidence);
    _evalCount++;

    if (_traits.batchTrainFrequency() > 0 && _evalCount % _traits.batchTrainFrequency() == 0)
    {
      _batchTrainNeeded = true;
    }

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
    if (B - A * A != 0.0) {
      eSR = A / MathSqrt(B - A * A);
    }
    _history.add("ema_SR", eSR);

    // Also write the norm of the theta vector:
    _history.add("theta_norm", _theta.norm());
  }

  return ready;
}

double nvRRLModel::predict(const nvVecd &params, const nvVecd &theta)
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

  return predict(params, _theta);
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

  if (_traits.batchTrainLength() < 0) {
    // We do not update the mean and deviation when using batch training.
    // We can compute the returns mean and deviation right here:
    _returnMean = _lastReturns.mean();
    _returnDev = _lastReturns.deviation();
  }

  if (_traits.returnsMeanDevFixed())
  {
    _returnMean = _traits.returnsMean();
    _returnDev = _traits.returnsDev();
  }
}

void nvRRLModel::computeWeightDelta(nvRRLOnlineTrainingContext &ctx, const nvVecd &rvec, double Ft_1)
{
  double A = ctx.A;
  double B = ctx.B;

  ctx.params.set(0, 1.0);
  ctx.params.set(1, Ft_1);
  ctx.params.set(2, (rvec - _returnMean) / _returnDev);

  double rt = rvec.back();

  double Ft = predict(ctx.params, _theta);
  double tcost = _traits.transactionCost();
  double Rt = Ft_1 * rt - tcost * MathAbs(Ft - Ft_1);

  if (B - A * A != 0.0) {
    // We can perform the training.
    // 1. Compute the new value of dFt/dw
    ctx.dFt = (ctx.params + ctx.dFt_1 * _theta[1]) * (1 - Ft * Ft);

    // 2. compute dRt/dw
    double dsign = tcost * nv_sign(Ft - Ft_1);
    ctx.dRt = ctx.dFt_1 * (rt + dsign) - ctx.dFt * dsign;

    // 3. compute dDt/dw
    ctx.dDt = ctx.dRt * (B - A * Rt) / MathPow(B - A * A, 1.5);

    //logDEBUG("New theta norm: "<< _theta.norm());

    // Advance one step:
    ctx.dFt_1 = ctx.dFt;
  }
  else {
    ctx.dDt.fill(0.0);
  }

  // Use Rt to update A and B:
  double adapt = 0.01; // TODO: Provide as trait.
  ctx.A = A + adapt * (Rt - A);
  ctx.B = B + adapt * (Rt * Rt - B);
}

void nvRRLModel::performOnlineTraining(nvRRLOnlineTrainingContext &ctx)
{
  // For now we just use the current return vector to perform the training.
  double Ft_1 = getCurrentSignal();

  // Compute the delta corresponding to the current sample:
  computeWeightDelta(ctx, _evalReturns, Ft_1);

  // Update Theta vector:
  double learningRate = 0.01; // TODO: provide as trait.
  _theta += ctx.dDt * learningRate;

  // Validate the norm of the theta vector:
  validateThetaNorm();
}

void nvRRLModel::performBatchTraining()
{
  // Should use a cost function to perform training here.
  nvRRLCostFunction_SR costfunc(_traits);

  costfunc.setTrainContext(_context);
  costfunc.setReturns(_batchTrainReturns);

  nvVecd initx(_theta);
  if (!_traits.warmInit()) {
    // We don't use the previous value of theta:
    initx.fill(1.0);
  }

  double cost = costfunc.train(initx, _theta);
  logDEBUG("Acheived best cost: " << cost);

  if (!_traits.returnsMeanDevFixed())
  {
    _returnMean = _batchTrainReturns.mean();
    _returnDev = _batchTrainReturns.deviation();
  }

  // Check the results by computing the sharpe ratio:
  nvVecd rets;
  evaluate(_batchTrainReturns, rets);
  double sr = nv_sharpe_ratio(rets);
  logDEBUG("Computed training sharpe ratio: " << sr);
}

void nvRRLModel::performBatchTraining_simple()
{
  // We use the batch training vector ne times:
  int numEpochs = 10;
  int num = (int)_batchTrainReturns.size();
  int ni = _traits.numInputReturns();
  nvVecd rvec(ni);
  nvVecd totaldDt(_theta.size());

  for (int i = 0; i < numEpochs; ++i) {

    // Prepare the per epoch data:
    double Ft_1 = 0.0;
    _onlineContext.dFt_1.fill(0);
    totaldDt.fill(0);

    for (int j = 0; j < num; ++j) {
      rvec.push_back(_batchTrainReturns[j]);
      if (j < ni - 1) {
        continue;
      }

      // The vector is ready for usage:
      computeWeightDelta(_onlineContext, rvec, Ft_1);

      // Add the delta to the total:
      totaldDt += _onlineContext.dDt;
      Ft_1 = predict(_onlineContext.params, _theta);
    }

    // Update the theta vector:
    // Uupdate Theta vector:
    double learningRate = 0.01; // TODO: provide as trait.
    _theta += totaldDt * learningRate / num;

    // Validate the norm of the theta vector:
    validateThetaNorm();
  }
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

void nvRRLModel::initOnlineContext(nvRRLOnlineTrainingContext &context)
{
  logDEBUG("Initializing online training context");
  context.A = 0.0;
  context.B = 0.0;
  context.dFt_1.resize(_theta.size());
  context.dDt.resize(_theta.size());
  context.params.resize(_theta.size());
}

void nvRRLModel::validateThetaNorm()
{
  double tn = _theta.norm();
  double maxNorm = 5.0;
  if (tn > maxNorm) {
    _theta *= exp(-tn / maxNorm + 1);
  }
}

void nvRRLModel::evaluate(const nvVecd &returns, nvVecd &rets)
{
  int ni = _traits.numInputReturns();
  nvVecd rvec(ni);

  double Ft_1 = 0.0;
  double Ft, Rt, rt;

  double tcost = _traits.transactionCost();

  nvVecd params(ni + 2);
  params.set(0, 1.0);

  int num = (int)returns.size();

  for (int i = 0; i < num; ++i)
  {
    rt = returns[i];
    rvec.push_back(rt);
    if (i < ni - 1) {
      continue; // Not enough data yet.
    }

    // We have enough data, evaluate the new position:
    params.set(1, Ft_1);
    params.set(2, (rvec - _returnMean) / _returnDev);

    Ft = predict(params, _theta);

    // Compute the return:
    Rt = Ft_1 * rt - tcost * MathAbs(Ft - Ft_1);

    // Add the new return to the list:
    rets.push_back(Rt);

    // Update previous signal:
    Ft_1 = Ft;
  }
}
