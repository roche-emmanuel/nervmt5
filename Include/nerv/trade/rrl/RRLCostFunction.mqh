
#include <nerv/core.mqh>
#include "RRLTrainTraits.mqh"

/*
Base class used for the implementation of a cost function for RRL batch training.
*/
class nvRRLCostFunction : public CNDimensional_Grad
{

protected:
  nvRRLTrainTraits _traits;

  nvVecd _nrets; // normalized returns.
  nvVecd _grad; // vector holding the latest gradient computed.
  nvVecd _x; // vector holding the latest parameters evaluated.

  double _bestCost;
  nvVecd _bestX;

public:
  /* Default constructor from traits. */
  nvRRLCostFunction(const nvRRLTrainTraits &traits);

  /* Method called to assign cost traits to this cost function.
    When assigning, the returns vector will be used to compute a normalized
    return vector. */
  void setTraits(const nvRRLTrainTraits &traits);

  /* Rest the best cost and best X parameters values discovered so far.
    This method is called by setTraits() */
  void reset();

  /* Retrieve the best cost and x parameter discovered so far. */
  double getBestCost(nvVecd& x) const;

  /* Main method used to pass the function value and gradient vector to the optimization procedure. */
  virtual void Grad(double &x[], double &func, double &grad[], CObject &obj);

  /* cost function using the simple sharpe ratio base utility.
    This method will return the current cost corresponding to the utility function
    and ensure that the gradient vector is updated. */
  double sr_cost(const nvVecd &x, nvVecd &grad);
};


//////////////////////////////////// implementation part ///////////////////////////
nvRRLCostFunction::nvRRLCostFunction(const nvRRLTrainTraits &traits)
{
  setTraits(traits);
}

void nvRRLCostFunction::setTraits(const nvRRLTrainTraits &traits)
{
  _traits = traits;
  CHECK(_traits.returns().size() > 0, "Invalid returns vector in CostTraits");

  // Compute the normalized returns here:
  _nrets = _traits.returns().stdnormalize();

  // Reset the results:
  reset();
}

void nvRRLCostFunction::reset()
{
  _bestCost = 1e10;
  _bestX.resize();
}

double nvRRLCostFunction::getBestCost(nvVecd& x) const
{
  x = _bestX;
  return _bestCost;
}

void nvRRLCostFunction::Grad(double &x[], double &func, double &grad[], CObject &obj)
{
  // Retrieve the x parameter:
  _x = x;

  // Compute the cost and gradient:
  func = sr_cost(_x, _grad);

  // update the gradient variable:
  _grad.toArray(grad);

  if (func <= _bestCost)
  {
    _bestCost = func;
    _bestX = x;
  }
}

double nvRRLCostFunction::sr_cost(const nvVecd &x, nvVecd &grad)
{
  // Train the model with the given inputs for a given number of epochs.
  nvVecd *returns = _traits.returns();
  double tcost = _traits.transactionCost();
  uint size = returns.size();
  
  nvVecd theta = x;
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
    rt = returns[i];

    // push a new value on the rvec:
    rvec.push_back(rtn);
    if (i < ni - 1)
      continue;

    //logDEBUG("On iteration " << i <<" rt="<<rt<<", rtn="<<rtn);

    if (i == 0 && _traits.useInitialSignal()) {
      // Force the initial Ft_1 value:
      Ft_1 = _traits.initialSignal();
    }

    // Prepare the parameter vector:
    params.set(1, Ft_1);
    params.set(2, rvec);

    // The rvec is ready for usage, so we build a prediction:
    //double val = params*theta;
    //logDEBUG("Pre-tanh value: "<<val);
    Ft = nv_tanh(params * theta);
    //logDEBUG("Prediction at "<<i<<" is: Ft="<<Ft);

    if (i == size - 1 && _traits.useFinalSignal()) {
      // Force the final Ft value:
      Ft = _traits.finalSignal();
    }

    // From that we can build the new return value:
    Rt = Ft_1 * rt - tcost * MathAbs(Ft - Ft_1);
    //logDEBUG("Return at "<<i<<" is Rt=" << Rt);

    // Increment the value of A and B:
    A += Rt;
    B += Rt * Rt;

    // we can compute the new derivative dFtdw
    dFt = (params + dFt_1 * theta[1]) * (1.0 - Ft * Ft);

    // Now we can compute dRtdw:
    dsign = tcost * nv_sign(Ft - Ft_1);
    dRt = dFt_1 * (rt + dsign) - dFt * dsign;

    sumdRt += dRt;
    sumRtdRt += dRt * Rt;

    // Update the recurrent values:
    Ft_1 = Ft;
    dFt_1 = dFt;
  }

  //logDEBUG("Done with all samples.");

  //logDEBUG("Num samples: " << ns);

  // Rescale A and B:
  A /= ns;
  B /= ns;

  //logDEBUG("A="<<A<<", B="<<B);

  // Rescale sumdRt and sumRtdRt:
  sumdRt *= 1.0 / ns;
  sumRtdRt *= 2.0 / ns; // There is a factor of 2 to keep in mind here.

  CHECK(B - A * A != 0.0, "Invalid values for A=" << A << " and B=" << B);

  // Now we can compute the derivatives of the sharpe ratio with respect to A and B:
  double dSdA = B / pow(B - A * A, 1.5);
  double dSdB = -0.5 * A / pow(B - A * A, 1.5);

  // finally we can compute the sharpe ratio derivative:
  grad = (sumdRt * dSdA + sumRtdRt * dSdB) * (-1.0);

  // Compute the current sharpe ratio:
  double sr = A / MathSqrt(B - A * A);
  return -sr;
}
