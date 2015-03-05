
#include <nerv/core.mqh>
#include <nerv/trades.mqh>
#include <nerv/trade/rrl/RRLModelTraits.mqh>
#include <nerv/trade/rrl/RRLTrainContext_SR.mqh>

class nvRRLCostFunction_SR : public nvCostFunctionBase
{
protected:
  nvRRLModelTraits _traits;
  nvRRLTrainContext_SR _ctx;

  nvVecd _returns;
  nvVecd _nrets;

public:
  nvRRLCostFunction_SR(const nvRRLModelTraits &traits);

  virtual void setReturns(const nvVecd &returns);
  virtual nvTrainContext* getTrainContext() const;

  virtual void computeCost();
  virtual double train(const nvVecd &initx, nvVecd &xresult);

  virtual double performStochasticTraining(const nvVecd& x, nvVecd& result, double learningRate);

  virtual int getNumDimensions() const;
};


//////////////////////////////////// implementation part ///////////////////////////
nvRRLCostFunction_SR::nvRRLCostFunction_SR(const nvRRLModelTraits &traits)
  : nvCostFunctionBase(traits.numInputReturns() + 2)
{
  _traits = traits;
  _ctx.init(traits);
}

nvTrainContext* nvRRLCostFunction_SR::getTrainContext() const
{
  return GetPointer(_ctx);
}

void nvRRLCostFunction_SR::setReturns(const nvVecd &returns)
{
  _returns = returns;
  if (_traits.returnsMeanDevFixed()) {
    //logDEBUG("SR cost using mean: "<<_traits.returnsMean()<<", dev:"<<_traits.returnsDev());
    _nrets = (returns - _traits.returnsMean()) / _traits.returnsDev();
  }
  else {
    _nrets = returns.stdnormalize();
  }
}

double nvRRLCostFunction_SR::train(const nvVecd &initx, nvVecd &xresult)
{
  // Initialize the context here:

  // To be accurate this training should start with the state that we had at the beginning
  // of the training phase.
  // Say the input vector contains on numInputReturns() elements
  // This means we should train with the latest values observed so far. (at _returnsMoment1.size()-1)
  // Otherwise, for each additional element we move one step back in time.
  _ctx.loadState((int)_returns.size());

  return dispatch_train(_traits, initx, xresult);
}

void nvRRLCostFunction_SR::computeCost()
{
  // Train the model with the given inputs for a given number of epochs.
  double tcost = _traits.transactionCost();
  uint size = _returns.size();

  nvVecd theta = _x;
  uint nm = theta.size();
  uint ni = nm - 2;

  CHECK(size >= ni, "Not enough return values: " << size << "<" << ni);

  // Compute the number of samples we have:
  uint ns = size - ni + 1;
  CHECK(ns >= 2, "We need at least 2 samples to perform batch training.");

  // Initialize the rvec:
  nvVecd rvec(ni);

  double Ft, Ft_1, rt, rtn, Rt, A, B, dsign;
  Ft_1 = A = B = 0.0;

  // dF0 is a zero vector.
  nvVecd dFt_1(nm);
  nvVecd dFt(nm);
  nvVecd dRt(nm);

  nvVecd sumdRt(nm);
  nvVecd sumRtdRt(nm);

  nvVecd params(nm);

  params.set(0, 1.0);

  // Iterate on each sample:
  for (uint i = 0; i < size; ++i)
  {
    rtn = _nrets[i];
    rt = _returns[i];

    // push a new value on the rvec:
    rvec.push_back(rtn);
    if (i < ni - 1)
      continue;

    //logDEBUG("On iteration " << i <<" rt="<<rt<<", rtn="<<rtn);

    // if (i == 0 && ctx.useInitialSignal) {
    //   // Force the initial Ft_1 value:
    //   Ft_1 = ctx.initialSignal;
    // }

    // Prepare the parameter vector:
    params.set(1, Ft_1);
    params.set(2, rvec);

    // The rvec is ready for usage, so we build a prediction:
    //double val = params*theta;
    //logDEBUG("Pre-tanh value: "<<val);
    Ft = nv_tanh(params * theta);
    //logDEBUG("Prediction at "<<i<<" is: Ft="<<Ft);

    // if (i == size - 1 && _traits.useFinalSignal()) {
    //   // Force the final Ft value:
    //   Ft = _traits.finalSignal();
    // }

    // From that we can build the new return value:
    Rt = Ft_1 * rt - tcost * MathAbs(Ft - Ft_1);
    //logDEBUG("Return at "<<i<<" is Rt=" << Rt);

    // Increment the value of A and B:
    A += Rt;
    B += Rt * Rt;

    if (_computeGradient)
    {
      // we can compute the new derivative dFtdw
      dFt = (params + dFt_1 * theta[1]) * (1.0 - Ft * Ft);

      // Now we can compute dRtdw:
      dsign = tcost * nv_sign(Ft - Ft_1);
      dRt = dFt_1 * (rt + dsign) - dFt * dsign;

      sumdRt += dRt;
      sumRtdRt += dRt * Rt;

      // Update the recurrent values:
      dFt_1 = dFt;
    }

    Ft_1 = Ft;
  }

  //logDEBUG("Done with all samples.");

  //logDEBUG("Num samples: " << ns);

  // Rescale A and B:
  A /= ns;
  B /= ns;
  CHECK(B - A * A != 0.0, "Invalid values for A=" << A << " and B=" << B);

  // Compute the current sharpe ratio:
  double sr = A / MathSqrt(B - A * A);

  //logDEBUG("A="<<A<<", B="<<B);

  if (_computeGradient)
  {
    // Rescale sumdRt and sumRtdRt:
    sumdRt *= 1.0 / ns;
    sumRtdRt *= 2.0 / ns; // There is a factor of 2 to keep in mind here.

    // Now we can compute the derivatives of the sharpe ratio with respect to A and B:
    double dSdA = B / pow(B - A * A, 1.5);
    double dSdB = -0.5 * A / pow(B - A * A, 1.5);

    // finally we can compute the sharpe ratio derivative:
    nvVecd thetab(theta);
    thetab.set(0, 0.0);

    _grad = (sumdRt * dSdA + sumRtdRt * dSdB) * (-1.0) + thetab * _traits.lambda();
  }

  // Compute the cost regularization:
  _cost = -sr + 0.5 * _traits.lambda() * (theta.norm2() - theta[0] * theta[0]);
}

double nvRRLCostFunction_SR::performStochasticTraining(const nvVecd& x, nvVecd& result, double learningRate)
{
  CHECK_PTR(_ctx, "Invalid context pointer.");

  int size = (int)_returns.size();
  _ctx.loadState(size);

  double rtn, rt;

  double tcost = _traits.transactionCost();
  double maxNorm = 5.0; // TODO: provide as trait.
  double A,B;

  nvVecd theta = x;
  int nm = (int)theta.size();
  int ni = nm - 2;

  nvVecd rvec(ni);

  _ctx.params.set(0, 1.0);

  for (int i = 0; i < size; ++i)
  {
    rtn = _nrets[i];
    rt = _returns[i];

    rvec.push_back(rtn);
    if (i < ni - 1)
      continue;

    _ctx.params.set(1, _ctx.Ft_1);
    _ctx.params.set(2, rvec);

    double Ft = predict(_ctx.params, theta);

    double Rt = _ctx.Ft_1 * rt - tcost * MathAbs(Ft - _ctx.Ft_1);
    
    A = _ctx.A;
    B = _ctx.B;

    if (B - A * A != 0.0) {
      // We can perform the training.
      // 1. Compute the new value of dFt/dw
      _ctx.dFt = (_ctx.params + _ctx.dFt_1 * theta[1]) * (1 - Ft * Ft);

      // 2. compute dRt/dw
      double dsign = tcost * nv_sign(Ft - _ctx.Ft_1);
      _ctx.dRt = _ctx.dFt_1 * (rt + dsign) - _ctx.dFt * dsign;

      // 3. compute dDt/dw
      _ctx.dDt = _ctx.dRt * (B - A * Rt) / MathPow(B - A * A, 1.5);

      // logDEBUG("New theta norm: "<< _theta.norm());

      // Advance one step:
      _ctx.dFt_1 = _ctx.dFt;
    }
    else {
      _ctx.dDt.fill(0.0);
    }

    // Now we apply the learning:
    theta += _ctx.dDt * learningRate;

    // Validate the norm of the theta vector:
    validateNorm(theta, maxNorm);

    // As suggested by [Dempster - 2004] here we can re-compute the value of Ft anf Rt
    // using the *supposedly* better value of theta:
    // Note: this change does not provide a positive feedback and instead will
    // reduce the final wealth.
    // Ft = nv_tanh(_ctx.params * theta);
    // Rt = _ctx.Ft_1 * rt - tcost * MathAbs(Ft - _ctx.Ft_1);

    // Update previsou signal:
    _ctx.Ft_1 = Ft;

    // Use Rt to update A and B:
    _ctx.addReturn(Rt);

    // Save the current state of the train context:
    _ctx.pushState();
  }

  // Once done we the training we provide the final value of theta:
  result = theta;
  //logDEBUG("Theta norm after Stochastic training: "<< theta.norm());

  // Compute the final sharpe ratio:
  double sr = _ctx.getSR();

  return -sr;
}

int nvRRLCostFunction_SR::getNumDimensions() const
{
  return _traits.numInputReturns()+2;
}
