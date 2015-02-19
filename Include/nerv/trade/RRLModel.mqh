//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include <nerv/core.mqh>
#include <nerv/math.mqh>

double rrlCostFunction(nvVecd *nrets, nvVecd *returns, double tcost, nvVecd *grad, nvVecd* theta)
{
  // Train the model with the given inputs for a given number of epochs.
  uint size = returns.size();
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
    rtn = nrets[i];
    rt = returns[i];

    // push a new value on the rvec:
    rvec.push_back(rtn);
    if (i < ni - 1)
      continue;

    //logDEBUG("On iteration " << i <<" rt="<<rt<<", rtn="<<rtn);

    // Prepare the parameter vector:
    params.set(1, Ft_1);
    params.set(2, rvec);

    // The rvec is ready for usage, so we build a prediction:
    //double val = params*theta;
    //logDEBUG("Pre-tanh value: "<<val);
    Ft = nv_tanh(params*theta);
    //logDEBUG("Prediction at "<<i<<" is: Ft="<<Ft);

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

class nvRRLModel : public nvObject
{
protected:
  // Number of return inputs:
  uint _numInputs;

  // Learning rate applying during training:
  double _learningRate;

  // max norm allowed for theta vector:
  double _maxNorm;

  // Theta parameters:
  nvVecd *_theta;

  bool _normalizeInputs;

public:
  nvRRLModel(uint num)
  {
    _numInputs = num;
    _learningRate = 0.01;
    _maxNorm = 2.0;
    _normalizeInputs = true;

    // Prepare the vector containing the theta values:
    // We need 2 additional coeffs for the u and w coeffs
    _theta = new nvVecd(_numInputs + 2);

    // generate initial random coefficients:
    //_theta.randomize(-1.0, 1.0);
    _theta.fill(1.0); // Initialize with 1.0.
    checkNorm();

    //logDEBUG("Initial theta vector is: " << _theta);
  }

  ~nvRRLModel()
  {
    delete _theta;
  }

  void checkNorm()
  {
    // Prevent theta from becoming too big:
    //if(_theta.norm()>1.0) {
    //  _theta.normalize(0.8);
    //}

    //if(MathMax(MathAbs(_theta.max()),MathAbs(_theta.min())) > 5.0) {
    //  _theta *= 0.95;
    //}

    //double tn = _theta.norm()/_maxNorm;
    //if(tn>1.0) {
    //  _theta *= MathExp(-tn + 1);
    //}
  }

  double predict(nvVecd *params) const
  {
    double val = _theta * params;
    //logDEBUG("Theta vector: "<<_theta);
    //logDEBUG("Param vector: "<<params);
    //logDEBUG("Pre tanh value: "<<val);
    return nv_tanh(val);
  }

  //double computeReturn(double rt, double tcost, double Ft, double Ft_1) const
  //{
    //logDEBUG("Computing Rt with Ft_1=" << Ft_1 << " and rt=" << rt);
    //return Ft_1 * rt - tcost * MathAbs(Ft - Ft_1);
  //}

  double train_batch(nvVecd *nrets, nvVecd *returns, double tcost)
  {
    nvVecd dSt(_numInputs + 2);

    double sr = rrlCostFunction(nrets, returns, tcost, GetPointer(dSt),_theta);

    // Perform gradient descent:
    _theta -= dSt * _learningRate;
    checkNorm();

    return -sr;
  }

  void train(nvVecd *returns, double tcost, uint nepochs, nvVecd *nretsvec = NULL, nvVecd *sharpe_ratios = NULL)
  {
    uint ns = returns.size() - _numInputs + 1;

    if (sharpe_ratios != NULL)
    {
      CHECK(sharpe_ratios.size() == 0, "Invalid sharpe ratio vector length.");
    }

    nvVecd nrets(returns.size());
    if (nretsvec != NULL)
    {
      nrets = nretsvec;
    }
    else
    {
      nrets = returns.stdnormalize();
    }

    double sr;
    for (uint i = 0; i < nepochs; ++i)
    {
      sr = train_batch(GetPointer(nrets), returns, tcost);
      if (sharpe_ratios)
        sharpe_ratios.push_back(sr);
    }
  }
};
