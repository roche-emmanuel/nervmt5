
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

#ifdef USE_OPTIMIZATIONS
  double _arets[];
  double _anrets[];
#endif

public:
  nvRRLCostFunction_DDR(const nvRRLModelTraits &traits);

  virtual void setReturns(const nvVecd &returns);
  virtual nvTrainContext* getTrainContext() const;

  virtual void computeCost();
  virtual double train(const nvVecd &initx, nvVecd &xresult);

  virtual double performStochasticTraining(const nvVecd& x, nvVecd& result, double learningRate);

  virtual int getNumDimensions() const;
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

#ifdef USE_OPTIMIZATIONS
  _returns.toArray(_arets);
  _nrets.toArray(_anrets);
#endif  
}

double nvRRLCostFunction_DDR::train(const nvVecd &initx, nvVecd &xresult)
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

void nvRRLCostFunction_DDR::computeCost()
{
  NO_IMPL();
}

double nvRRLCostFunction_DDR::performStochasticTraining(const nvVecd& x, nvVecd& result, double learningRate)
{
  CHECK_PTR(_ctx, "Invalid context pointer.");

  int size = (int)_returns.size();
  _ctx.loadState(size);

  double rt;

  // ratio of conversion used to avoid precision issues:
  // we just count the returns in units 0.1 of pips (eg. 5 decimals):
  // This could be turned off by using a ratio of 1.0 instead.
  double ratio = 0.00001;

  double tcost = _traits.transactionCost() / ratio;
  double maxNorm = 5.0; // TODO: provide as trait.
  double A, DD2, DD;

  int nm = (int)x.size();
  int ni = nm - 2;

#ifndef USE_OPTIMIZATIONS
  nvVecd theta = x;
  nvVecd rvec(ni);
#else
  double adFt[];
  double adFt_1[];
  double theta[];

  x.toArray(theta);

  ArrayResize(adFt, nm);
  ArrayFill(adFt, 0, nm, 0.0);
  ArrayResize(adFt_1, nm);
  ArrayFill(adFt_1, 0, nm, 0.0);

  double param, m1, m2, d1, t1, norm;
#endif

  _ctx.params.set(0, 1.0);

  for (int i = 0; i < size; ++i)
  {

#ifndef USE_OPTIMIZATIONS
    rt = _returns[i] / ratio;
    rvec.push_back(_nrets[i]);
    if (i < ni - 1)
      continue;

    _ctx.params.set(1, _ctx.Ft_1);
    _ctx.params.set(2, rvec);

    double Ft = predict(_ctx.params, theta);
#else
    if (i < ni - 1)
      continue;
    rt = _arets[i] / ratio;

    int id = i - ni + 1;
    double Ft = theta[0] + _ctx.Ft_1 * theta[1];
    for (int j = 0; j < ni; ++j) {
      Ft += _anrets[id + j] * theta[j + 2];
    }
    Ft = nv_tanh(Ft);
#endif

    double Rt = _ctx.Ft_1 * rt - tcost * MathAbs(Ft - _ctx.Ft_1);

    DD2 = _ctx.DD2;
    A = _ctx.A;

    if (DD2 != 0.0) {
      // Needed variables:
      double dsign = tcost * nv_sign(Ft - _ctx.Ft_1);
      DD = sqrt(DD2);


      // We can perform the training.
#ifndef USE_OPTIMIZATIONS
      // 1. Compute the new value of dFt/dw
      _ctx.dFt = (_ctx.params + _ctx.dFt_1 * theta[1]) * ((1 - Ft) * (1 + Ft));

      // 2. compute dRt/dw
      _ctx.dRt = _ctx.dFt_1 * (rt + dsign) - _ctx.dFt * dsign;


      // 3. compute dDt/dw
      if (Rt > 0.0) {
        _ctx.dDt = _ctx.dRt * (1.0 / DD);
      }
      else {
        _ctx.dDt = _ctx.dRt * ((DD2 - A * Rt) / (DD * DD2));
      }

      // logDEBUG("New theta norm: "<< _theta.norm());

      // Advance one step:
      _ctx.dFt_1 = _ctx.dFt;

      // Now we apply the learning:
      theta += _ctx.dDt * learningRate;
#else
      m1 = ((1 - Ft) * (1 + Ft));
      t1 = theta[1];
      d1 = rt + dsign;
      m2 = Rt > 0.0 ? (1.0 / DD) : ((DD2 - A * Rt) / (DD * DD2));
      m2 *= learningRate;

      for (int j = 0; j < nm; ++j) {
        param = j == 0 ? 1.0 : j == 1 ? _ctx.Ft_1 : _anrets[id+j - 2];
        adFt[j] = (param + adFt_1[j] * t1) * m1;
        // theta[j] += (adFt_1[j] * d1 - adFt[j] * dsign) * m2 / m3 * learningRate;
        theta[j] += (adFt_1[j] * d1 - adFt[j] * dsign) * m2;
        adFt_1[j] = adFt[j];
      }
#endif
    }


    // Validate the norm of the theta vector:
#ifndef USE_OPTIMIZATIONS    
    validateNorm(theta, maxNorm);
#else
    norm = 0.0;
    for (int j = 0; j < nm; ++j) {
      norm += theta[j] * theta[j];
    }
    norm = sqrt(norm);
    if (norm > maxNorm) {
      for (int j = 0; j < nm; ++j) {
        theta[j] *= 0.75;
      }
      // theta *= MathMin(exp(-tn / maxNorm + 1),0.75);
    }
#endif

    // Update previsou signal:
    _ctx.Ft_1 = Ft;

    // Use Rt to update A and B:
    _ctx.addReturn(Rt);

    // Save the current state of the train context:
    _ctx.pushState();
  }

  // Once done we the training we provide the final value of theta:
  result = theta;
  CHECK(result.isValid(), "Invalid vector detected.");
  //logDEBUG("Theta norm after Stochastic training: "<< theta.norm());

  // Compute the final sharpe ratio:
  double ddr = _ctx.getDDR();

  return -ddr;
}

int nvRRLCostFunction_DDR::getNumDimensions() const
{
  return _traits.numInputReturns() + 2;
}
