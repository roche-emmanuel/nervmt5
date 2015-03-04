
#include <nerv/core.mqh>
#include <nerv/trades.mqh>
#include <nerv/trade/rrl/RRLModelTraits.mqh>
#include <nerv/trade/rrl/RRLTrainContext_DDR.mqh>

class nvRRLCostFunction_DDR : public nvCostFunctionBase
{
protected:
  nvRRLModelTraits _traits;
  nvRRLTrainContext_DDR _ctx;

  nvVecd _returns;
  nvVecd _nrets;

public:
  nvRRLCostFunction_DDR(const nvRRLModelTraits &traits);

  virtual void setReturns(const nvVecd &returns);
  virtual nvTrainContext* getTrainContext() const;

  virtual void computeCost();
  virtual double train(const nvVecd &initx, nvVecd &xresult);

  virtual double performStochasticTraining(const nvVecd& x, nvVecd& result, double learningRate, bool restore = false);
};


//////////////////////////////////// implementation part ///////////////////////////
nvRRLCostFunction_DDR::nvRRLCostFunction_DDR(const nvRRLModelTraits &traits)
  : nvCostFunctionBase(traits.numInputReturns() + 2)
{
  _traits = traits;
  _ctx.init(traits);
}

nvTrainContext* nvRRLCostFunction_DDR::getTrainContext() const
{
  return GetPointer(_ctx);
}

void nvRRLCostFunction_DDR::setReturns(const nvVecd &returns)
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

double nvRRLCostFunction_DDR::train(const nvVecd &initx, nvVecd &xresult)
{
  // Initialize the context here:

  // To be accurate this training should start with the state that we had at the beginning
  // of the training phase.
  // Say the input vector contains on numInputReturns() elements
  // This means we should train with the latest values observed so far. (at _returnsMoment1.size()-1)
  // Otherwise, for each additional element we move one step back in time.
  _ctx.loadState((int)xresult.size() - _traits.numInputReturns());

  return dispatch_train(_traits, initx, xresult);
}

void nvRRLCostFunction_DDR::computeCost()
{
  NO_IMPL();
}

double nvRRLCostFunction_DDR::performStochasticTraining(const nvVecd& x, nvVecd& result, double learningRate, bool restore)
{
  CHECK_PTR(_ctx, "Invalid context pointer.");

  // Assign the A and B value from the initial variables:
  double initialA = _ctx.A;
  double initialDD2 = _ctx.DD2;
  double initialF = _ctx.Ft_1;
  nvVecd initialdFt = _ctx.dFt_1;

  double A = _ctx.A;
  double DD2 = _ctx.DD2;

  int size = (int)_returns.size();
  double rtn, rt;

  double tcost = _traits.transactionCost();
  double maxNorm = 5.0; // TODO: provide as trait.
  double adapt = 0.01; // TODO: Provide as trait.

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

    double Ft = nv_tanh(_ctx.params * theta);

    double Rt = _ctx.Ft_1 * rt - tcost * MathAbs(Ft - _ctx.Ft_1);

    if (DD2 != 0.0) {
      // We can perform the training.
      // 1. Compute the new value of dFt/dw
      _ctx.dFt = (_ctx.params + _ctx.dFt_1 * theta[1]) * (1 - Ft * Ft);

      // 2. compute dRt/dw
      double dsign = tcost * nv_sign(Ft - _ctx.Ft_1);
      _ctx.dRt = _ctx.dFt_1 * (rt + dsign) - _ctx.dFt * dsign;

      double DD = sqrt(DD2);

      // 3. compute dDt/dw
      if (Rt > 0.0) {
        _ctx.dDt = _ctx.dRt * (1.0 / DD);
      }
      else {
        _ctx.dDt = _ctx.dRt * ((DD2 - A * Rt) / (DD*DD2));
      }

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
    A = A + adapt * (Rt - A);
    double val = MathMin(Rt,0);
    DD2 = DD2 + adapt * (val * val - DD2);
  }

  // Once done we the training we provide the final value of theta:
  result = theta;
  //logDEBUG("Theta norm after Stochastic training: "<< theta.norm());

  // Compute the final sharpe ratio:
  double ddr = 0.0;
  if (DD2 != 0.0) {
    ddr = A / sqrt(DD2);
  }

  if (restore) {
    // We need to restore the context variables:
    _ctx.A = initialA;
    _ctx.DD2 = initialDD2;
    _ctx.Ft_1 = initialF;
    _ctx.dFt_1 = initialdFt;
  }
  else {
    _ctx.A = A;
    _ctx.DD2 = DD2;
  }

  return -ddr;
}
