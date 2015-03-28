
#include <nerv/core.mqh>
#include <nerv/trades.mqh>
#include <nerv/trade/rrl/RRLModelTraits.mqh>
#include <nerv/trade/rrl/RRLCostFunction.mqh>
#include <nerv/trade/rrl/RRLTrainContext_DDR.mqh>

class nvRRLCostFunction_DDR : public nvRRLCostFunction
{
public:
  nvRRLCostFunction_DDR(const nvRRLModelTraits &traits);

  virtual void computeCost();

  virtual double performStochasticTraining(const nvVecd& x, nvVecd& result, double learningRate);

  virtual int getNumDimensions() const;

protected:
  virtual double getCurrentCost() const;
};


//////////////////////////////////// implementation part ///////////////////////////
nvRRLCostFunction_DDR::nvRRLCostFunction_DDR(const nvRRLModelTraits &traits)
  : nvRRLCostFunction(traits)
{
  _ctx = new nvRRLTrainContext_DDR(traits);
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

  int nm = (int)x.size();
  int ni = nm - 2;

#ifndef USE_OPTIMIZATIONS
  nvVecd theta = x;
  nvVecd rvec(ni);

  nvVecd params(nm);
  params.set(0, 1.0);  
#else
  double adFt[];
  double adFt_1[];
  double theta[];

  x.toArray(theta);

  ArrayResize(adFt, nm);
  ArrayFill(adFt, 0, nm, 0.0);
  ArrayResize(adFt_1, nm);
  ArrayFill(adFt_1, 0, nm, 0.0);

  double param, m1, d1, t1, norm;
#endif

  for (int i = 0; i < size; ++i)
  {

#ifndef USE_OPTIMIZATIONS
    rt = _returns[i] / ratio;
    rvec.push_back(_nrets[i]);
    if (i < ni - 1)
      continue;

    params.set(1, _ctx.Ft_1);
    params.set(2, rvec);

    double Ft = predict(params, theta);
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

    double mult = _ctx.computeMultiplier(learningRate,Rt);

    if(mult!=0.0) {
      // Needed variables:
      double dsign = tcost * nv_sign(Ft - _ctx.Ft_1);


      // We can perform the training.
#ifndef USE_OPTIMIZATIONS
      // 1. Compute the new value of dFt/dw
      _ctx.dFt = (params + _ctx.dFt_1 * theta[1]) * ((1 - Ft) * (1 + Ft));

      // 2. compute dRt/dw
      _ctx.dRt = _ctx.dFt_1 * (rt + dsign) - _ctx.dFt * dsign;


      // 3. compute dDt/dw
      // double m2 = Rt > 0.0 ? (1.0 / DD) : ((DD2 - A * Rt) / DD3);
      // m2 *= learningRate;

      // if (Rt > 0.0) {
      //   _ctx.dDt = _ctx.dRt * (1.0 / DD);
      // }
      // else {
      //   _ctx.dDt = _ctx.dRt * ((DD2 - A * Rt) / DD3);
      // }
      _ctx.dDt = _ctx.dRt;

      // logDEBUG("New theta norm: "<< _theta.norm());

      // Advance one step:
      _ctx.dFt_1 = _ctx.dFt;

      // Now we apply the learning:
      _ctx.dDt *= mult;
      theta += _ctx.dDt;
#else
      m1 = ((1 - Ft) * (1 + Ft));
      t1 = theta[1];
      d1 = rt + dsign;
      // m2 = Rt > 0.0 ? (1.0 / DD) : ((DD2 - A * Rt) / DD3);
      //m2 *= learningRate;

      for (int j = 0; j < nm; ++j) {
        param = j == 0 ? 1.0 : j == 1 ? _ctx.Ft_1 : _anrets[id+j - 2];
        adFt[j] = (param + adFt_1[j] * t1) * m1;
        // theta[j] += (adFt_1[j] * d1 - adFt[j] * dsign) * m2 / m3 * learningRate;
        theta[j] += (adFt_1[j] * d1 - adFt[j] * dsign) * mult;
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

double nvRRLCostFunction_DDR::getCurrentCost() const
{
  return -_ctx.getDDR();
}


