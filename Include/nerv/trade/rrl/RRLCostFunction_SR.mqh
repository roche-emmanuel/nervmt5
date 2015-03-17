
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

#ifdef USE_OPTIMIZATIONS
  double _arets[];
  double _anrets[];
#endif

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

#ifdef USE_OPTIMIZATIONS
  _returns.toArray(_arets);
  _nrets.toArray(_anrets);
#endif
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
  // CHECK_PTR(_ctx, "Invalid context pointer.");

  // int size = (int)_returns.size();
  // _ctx.loadState(size);

  double ratio = 0.00001;
  double tcost = _traits.transactionCost() / ratio;
  int size = (int)_returns.size();

  nvVecd theta = _x;
  int nm = (int)theta.size();
  int ni = nm - 2;

  CHECK(size >= ni, "Not enough return values: " << size << "<" << ni);

  // Compute the number of samples we have:
  uint ns = size - ni + 1;
  CHECK(ns >= 2, "We need at least 2 samples to perform batch training.");

  // Initialize the rvec:
  nvVecd rvec(ni);

  double Ft, Ft_1, rt, Rt, A, B, dsign;
  Ft_1 = A = B = 0.0;

#ifndef USE_OPTIMIZATIONS
  // dF0 is a zero vector.
  nvVecd dFt_1(nm);
  nvVecd dFt(nm);
  nvVecd dRt(nm);

  nvVecd sumdRt(nm);
  nvVecd sumRtdRt(nm);

  nvVecd params(nm);

  params.set(0, 1.0);
#else
  double adFt[];
  double adFt_1[];
  double atheta[];
  double sumdRt[];
  double sumRtdRt[];
  double agrad[];

  theta.toArray(atheta);

  ArrayResize(adFt, nm);
  ArrayFill(adFt, 0, nm, 0.0);
  ArrayResize(adFt_1, nm);
  ArrayFill(adFt_1, 0, nm, 0.0);
  ArrayResize(sumdRt, nm);
  ArrayFill(sumdRt, 0, nm, 0.0);
  ArrayResize(sumRtdRt, nm);
  ArrayFill(sumRtdRt, 0, nm, 0.0);
  ArrayResize(agrad, nm);

  double param, m1, d1, t1, dRt;
#endif

  // Iterate on each sample:
  for (int i = 0; i < size; ++i)
  {
#ifndef USE_OPTIMIZATIONS
    rt = _returns[i] / ratio;
    rvec.push_back(_nrets[i]);
    if (i < ni - 1)
      continue;

    // Prepare the parameter vector:
    params.set(1, Ft_1);
    params.set(2, rvec);

    // The rvec is ready for usage, so we build a prediction:
    Ft = nv_tanh(params * theta);
#else
    if (i < ni - 1)
      continue;
    rt = _arets[i] / ratio;

    int id = i - ni + 1;
    Ft = atheta[0] + Ft_1 * atheta[1];
    for (int j = 0; j < ni; ++j) {
      Ft += _anrets[id+j] * atheta[j + 2];
    }
    Ft = nv_tanh(Ft);
#endif

    // From that we can build the new return value:
    Rt = Ft_1 * rt - tcost * MathAbs(Ft - Ft_1);
    //logDEBUG("Return at "<<i<<" is Rt=" << Rt);

    // Increment the value of A and B:
    A += Rt;
    B += Rt * Rt;

    if (_computeGradient)
    {
      dsign = tcost * nv_sign(Ft - Ft_1);

#ifndef USE_OPTIMIZATIONS      
      // we can compute the new derivative dFtdw
      dFt = (params + dFt_1 * theta[1]) * ((1 - Ft) * (1 + Ft));

      // Now we can compute dRtdw:
      dRt = dFt_1 * (rt + dsign) - dFt * dsign;

      sumdRt += dRt;
      sumRtdRt += dRt * Rt;

      // Update the recurrent values:
      dFt_1 = dFt;
#else
      m1 = ((1 - Ft) * (1 + Ft));
      t1 = atheta[1];
      d1 = rt + dsign;

      for (int j = 0; j < nm; ++j) {
        param = j == 0 ? 1.0 : j == 1 ? Ft_1 : _anrets[id+j - 2];
        adFt[j] = (param + adFt_1[j] * t1) * m1;
        dRt = (adFt_1[j] * d1 - adFt[j] * dsign);
        sumdRt[j] += dRt;
        sumRtdRt[j] += Rt * dRt;
        adFt_1[j] = adFt[j];
      }
#endif      
    }

    Ft_1 = Ft;
  }

  //logDEBUG("Done with all samples.");

  //logDEBUG("Num samples: " << ns);

  // Rescale A and B:
  A /= ns;
  B /= ns;
  double sqB = sqrt(B);
  double BmAA = (sqB - A) * (sqB + A);

  CHECK( BmAA != 0.0, "Invalid values for A=" << A << " and B=" << B);

  // Compute the current sharpe ratio:
  double sr = A / MathSqrt(BmAA);

  //logDEBUG("A="<<A<<", B="<<B);

  if (_computeGradient)
  {
    // Now we can compute the derivatives of the sharpe ratio with respect to A and B:
    double dSdA = B / pow(BmAA, 1.5);
    double dSdB = -0.5 * A / pow(BmAA, 1.5);

#ifndef USE_OPTIMIZATIONS  
    // Rescale sumdRt and sumRtdRt:
    sumdRt *= 1.0 / ns;
    sumRtdRt *= 2.0 / ns; // There is a factor of 2 to keep in mind here.

    _grad = (sumdRt * dSdA + sumRtdRt * dSdB) * (-1.0);
#else

    for (int j = 0; j < nm; ++j) {
      agrad[j] = - sumdRt[j]*dSdA - sumRtdRt[j]*dSdB;
    }

    _grad = agrad;
#endif

    // finally we can compute the sharpe ratio derivative:
    if(_traits.lambda() > 0.0)
    {
      nvVecd thetab(theta);
      thetab.set(0, 0.0);

      _grad += thetab * _traits.lambda();      
    }    
  }

  // Compute the cost regularization:
  _cost = -sr + 0.5 * _traits.lambda() * (theta.norm2() - theta[0] * theta[0]);
}

double nvRRLCostFunction_SR::performStochasticTraining(const nvVecd& x, nvVecd& result, double learningRate)
{
  CHECK_PTR(_ctx, "Invalid context pointer.");

  int size = (int)_returns.size();
  _ctx.loadState(size);

  double rt;

  // ratio of conversion used to avoid precision issues:
  // we just count the returns in units 0.1 of pips (eg. 5 decimals):
  // This could be turned of by using a ratio of 1.0 instead.
  double ratio = 0.00001;

  double tcost = _traits.transactionCost() / ratio;
  double maxNorm = 5.0; // TODO: provide as trait.
  double A, B;

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

    double Ft = nv_tanh(_ctx.params * theta);
#else
    if (i < ni - 1)
      continue;
    rt = _arets[i] / ratio;

    int id = i - ni + 1;
    double Ft = theta[0] + _ctx.Ft_1 * theta[1];
    for (int j = 0; j < ni; ++j) {
      Ft += _anrets[id+j] * theta[j + 2];
    }
    Ft = nv_tanh(Ft);
#endif

    double Rt = _ctx.Ft_1 * rt - tcost * MathAbs(Ft - _ctx.Ft_1);

    A = _ctx.A;
    B = _ctx.B;

    if (B - A * A != 0.0) {
      // Needed variables:
      double dsign = tcost * nv_sign(Ft - _ctx.Ft_1);
      double sqB = sqrt(B);

      // We can perform the training.

#ifndef USE_OPTIMIZATIONS
      // 1. Compute the new value of dFt/dw
      // Note: replacing (1 - Ft^2) with (1-Ft)*(1+Ft) to avoid precision issues.

      _ctx.dFt = (_ctx.params + _ctx.dFt_1 * theta[1]) * ((1 - Ft) * (1 + Ft));

      // 2. compute dRt/dw
      _ctx.dRt = _ctx.dFt_1 * (rt + dsign) - _ctx.dFt * dsign;

      // 3. compute dDt/dw
      // _ctx.dDt = _ctx.dRt * (B - A * Rt) / MathPow(B - A * A, 1.5);
      // Note: replacing initial multiplier with enhanced formula to avoid precision issues:
      _ctx.dDt = _ctx.dRt; // * ((B - A * Rt) / MathPow((sqB - A) * (sqB + A), 1.5));

      double m2 = ((B - A * Rt) / MathPow((sqB - A) * (sqB + A), 1.5)) * learningRate;

      // Advance one step:
      _ctx.dFt_1 = _ctx.dFt;

      // Now we apply the learning:
      _ctx.dDt *= m2;
      theta += _ctx.dDt;
#else
      // // 1. Compute the new value of dFt/dw
      // _ctx.dFt = _ctx.dFt_1;
      // _ctx.dFt *= theta[1];
      // _ctx.dFt += _ctx.params;
      // _ctx.dFt *= ((1 - Ft) * (1 + Ft));

      // // 2. compute dRt/dw
      // _ctx.dRt = _ctx.dFt_1;
      // if (dsign == 0.0) {
      //   _ctx.dRt *= rt;
      // }
      // else {
      //   double rtdsign = 1.0 + rt / dsign;
      //   _ctx.dRt *= rtdsign;
      //   _ctx.dRt -= _ctx.dFt;
      //   _ctx.dRt *= dsign;
      // }

      // // 3. compute dDt/dw
      // _ctx.dDt = _ctx.dRt;
      // _ctx.dDt *= ((B - A * Rt) / MathPow((sqB - A) * (sqB + A), 1.5));

      // // Advance one step:
      // _ctx.dFt_1 = _ctx.dFt;

      // // Now we apply the learning:
      // _ctx.dDt *= learningRate;
      // theta += _ctx.dDt;

      m1 = ((1 - Ft) * (1 + Ft));
      t1 = theta[1];
      d1 = rt + dsign;
      m2 = ((B - A * Rt) / MathPow((sqB - A) * (sqB + A), 1.5)) * learningRate;
      // m2 = (B - A * Rt);
      // double m3 = MathPow((sqB - A) * (sqB + A), 1.5);

      for (int j = 0; j < nm; ++j) {
        param = j == 0 ? 1.0 : j == 1 ? _ctx.Ft_1 : _anrets[id+j - 2];
        adFt[j] = (param + adFt_1[j] * t1) * m1;
        // theta[j] += (adFt_1[j] * d1 - adFt[j] * dsign) * m2 / m3 * learningRate;
        theta[j] += (adFt_1[j] * d1 - adFt[j] * dsign) * m2;
        adFt_1[j] = adFt[j];
      }
#endif

      // logDEBUG("New theta norm: "<< _theta.norm());
    }

    //CHECK(theta.isValid(), "Invalid vector detected.");

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
  CHECK(result.isValid(), "Invalid vector detected.");
  //logDEBUG("Theta norm after Stochastic training: "<< theta.norm());

  // Compute the final sharpe ratio:
  double sr = _ctx.getSR();

  return -sr;
}

int nvRRLCostFunction_SR::getNumDimensions() const
{
  return _traits.numInputReturns() + 2;
}
