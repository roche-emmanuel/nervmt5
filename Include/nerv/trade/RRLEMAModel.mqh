
#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include "RRLModelBase.mqh"

double sigmoid(double z)
{
  return 1.0/(1.0+exp(-z));
}

double rrlemaCostFunction(nvVecd *nrets, nvVecd *returns, double tcost, nvVecd *grad, nvVecd *x)
{
  // We retrieve the EMA adaptation coefficient as a first element of the x vector:
  double eps = sigmoid(x[0]);
  nvVecd theta = x.subvec(1, x.size() - 1);

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

  double Ft, Ft_1, Gt, Gt_1, rt, rtn, Rt, A, B, dsign;
  Ft = Ft_1 = Gt = Gt_1 = A = B = 0.0;

  double dGtde, dGt_1de, dFtde, dFt_1de, dRtde;
  dGtde = dGt_1de = dFtde = dFt_1de = dRtde = 0.0;

  double wx = 0.0;

  // dF0 is a zero vector.
  nvVecd dFt_1(nm);
  nvVecd dFt(nm);
  nvVecd dGt_1(nm);
  nvVecd dGt(nm);
  nvVecd dRt(nm);

  nvVecd sumdRt(nm);
  nvVecd sumRtdRt(nm);

  double sumdRtde = 0.0;
  double sumRtdRtde = 0.0;

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

    wx = params * theta;

    // Compute the new value of Gt:
    Gt = Gt_1 + eps * (wx - Gt_1);

    // Compute the new value of Ft:
    Ft = nv_tanh(Gt);
    //logDEBUG("Prediction at "<<i<<" is: Gt="<<Gt<<", Ft="<<Ft<<", wx="<<wx<<" eps="<<eps);

    // From that we can build the new return value:
    Rt = Ft_1 * rt - tcost * MathAbs(Ft - Ft_1);
    //logDEBUG("Return at "<<i<<" is Rt=" << Rt <<", rt="<<rt<<", tcost="<<tcost);

    // Increment the value of A and B:
    A += Rt;
    B += Rt * Rt;

    // Now we compute the derivatives:
    // We start with dGt/dw:
    dGt = dGt_1 * (1 - eps) + (params + dFt_1 * theta[1]) * eps;


    // we can compute the new derivative dFtdw
    dFt = dGt * (1.0 - Ft * Ft);

    // We also need the derivative by eps:
    dGtde = dGt_1de + wx - Gt_1 + eps * (theta[1] * dFt_1de - dGt_1de);

    dFtde = (1.0 - Ft * Ft) * dGtde;


    // Now we can compute dRtdw:
    dsign = tcost * nv_sign(Ft - Ft_1);
    dRt = dFt_1 * (rt + dsign) - dFt * dsign;

    dRtde = dFt_1de * (rt + dsign) - dFtde * dsign;

    // Compute the summation parts:
    sumdRt += dRt;
    sumRtdRt += dRt * Rt;

    sumdRtde += dRtde;
    sumRtdRtde += Rt * dRtde;

    // Update the recurrent values:
    Ft_1 = Ft;
    dFt_1 = dFt;
    dFt_1de = dFtde;

    Gt_1 = Gt;
    dGt_1 = dGt;
    dGt_1de = dGtde;
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

  sumdRtde *= 1.0 / ns;
  sumRtdRtde *= 2.0 / ns;

  // by default, we set the derivative to zero (we are on a plateau far away from everything)
  grad.fill(0.0);

  // If we make no transaction at all then it means the adaptation ratio is becoming too small.
  // and in that case the sharpe ratio should become prohibitively negative:
  double sr = -1.0/MathMax(eps,1e-10);
	double one_eps = 1.0 + eps;

  if(A!=0.0 && B!=0.0)
  {
    CHECK(B - A * A != 0.0, "Invalid values for A=" << A << " and B=" << B);

    // Compute the current sharpe ratio:
    sr = A / MathSqrt(B - A * A);

    // Now we can compute the derivatives of the sharpe ratio with respect to A and B:
    double dSdA = B / pow(B - A * A, 1.5);
    double dSdB = -0.5 * A / pow(B - A * A, 1.5);


    // finally we can compute the sharpe ratio derivative:
    nvVecd dSdw = (sumdRt * dSdA + sumRtdRt * dSdB);

    double dSde = (sumdRtde * dSdA + sumRtdRtde * dSdB);

    // Build the opposite of the utility gradients:
    nvVecd dUdw = (dSdw / one_eps) * (-1.0);

    double dUde = (dSde / one_eps - sr / (one_eps * one_eps)) * (-1.0);
    double dUdz = dUde * eps * (1.0 - eps);

    // Assign the elements of the grad vector:
    grad.set(0, dUdz);
    grad.set(1, dUdw);
  }

  // Compute the value of the utility function:
  double U = sr / one_eps;

  // Return the opposite of the utility:
  return -U;
}

class nvRRLEMAEvaluator : public CNDimensional_Grad
{
protected:
  nvVecd _returns;
  nvVecd _nrets;

  nvVecd _grad;
  nvVecd _x;
  double _tcost;

  double _bestCost;
  nvVecd _bestX;

public:
  nvRRLEMAEvaluator(double tcost, nvVecd *returns) : _bestCost(1e10)
  {

    _returns = returns;
    _nrets = returns.stdnormalize();
    _tcost = tcost;
  }

  virtual void Grad(double &x[], double &func, double &grad[], CObject &obj)
  {
    _x = x;
    if(_grad.size()!=_x.size()) {
      _grad = _x;
    }
    
    //logDEBUG("Theta: "<<_x);
    func = rrlemaCostFunction(GetPointer(_nrets), GetPointer(_returns), _tcost, GetPointer(_grad), GetPointer(_x));
    //logDEBUG("Computed cost: "<<func);
    _grad.toArray(grad);

    if (func <= _bestCost)
    {
      _bestCost = func;
      _bestX = x;
    }
  };

  double getBestCost() const
  {
    return _bestCost;
  }

  nvVecd *getBestX() const
  {
    return GetPointer(_bestX);
  }
};

class nvRRLEMAModel : public nvRRLModelBase
{
protected:
  // Theta parameters:
  nvVecd _theta;
  double _eps;
	
  // params used for evaluation:
  nvVecd _params;

public:
  nvRRLEMAModel(uint num, int maxIts = 250) : _params(num+2), _theta(num+2),
    nvRRLModelBase(maxIts)
  {
    // Prepare the vector containing the theta values:
    // We need 2 additional coeffs for the u and w coeffs
    //nvVecd initial_theta(_numInputs + 2, 1.0);
    _theta.fill(1.0);
    _eps = 0.5;
  }

  ~nvRRLEMAModel()
  {
  }

  double predict(nvVecd *rvec, double Gt_1, double &signal)
  {
    //logDEBUG("Predicting with rvec="<<rvec);
    _params.set(0, 1.0);
    _params.set(1, signal); // initially signal should contain the previous signal.
    _params.set(2, (rvec - _rmean) / _rdev);

    double wx = _theta * _params;

    double Gt = Gt_1 + _eps * (wx - Gt_1);

    // update the value of Gt_1:
    signal = nv_tanh(Gt);
    //logDEBUG("Theta vector: "<<_theta);
    //logDEBUG("Param vector: "<<params);
    //logDEBUG("Gt value: "<<Gt);
    return Gt;
  }

  double getEvaluationEstimate() const
  {
    // Update the estimation for the evaluation phase duration:
    return 1.0/MathMax(_eps,0.01);
  }

  double train_cg(double tcost, nvVecd *init_x, nvVecd *returns)
  {
    // Prepare the training with MinCG:
    double x[];
    init_x.toArray(x);

    CMinCGStateShell state;
    CAlglib::MinCGCreate(x, state);

    CAlglib::MinCGSetCond(state, _epsg, _epsf, _epsx, _maxIts);

    nvRRLEMAEvaluator ev(tcost, returns);
    CNDimensional_Rep rep;

    CObject objdum;
    CAlglib::MinCGOptimize(state, ev, rep, false, objdum);

    CMinCGReportShell res;
    CAlglib::MinCGResults(state, x, res);

    nvVecd xvec = x;
    _eps = sigmoid(xvec[0]);
    _theta = xvec.subvec(1, xvec.size() - 1);

    double cost = ev.getBestCost();
    double sr = -cost * _eps;

    logDEBUG("Optimization done with best cost: " << ev.getBestCost() << ", eps=" << _eps << ", SR=" << sr);

    _rmean = returns.mean();
    _rdev = returns.deviation();

    //logDEBUG("Trained theta: "<<_theta);
    
    //logDEBUG("Estimated evalutation duration: "<<dur);

    //logDEBUG("rmean="<<_rmean<<", rdev="<<_rdev);

    //nvVecd bestTheta = ev.getBestX();
    //CHECK(bestTheta==_theta,"Mismatch in theta vectors: "<<_theta<<"!="<<bestTheta);

    return ev.getBestCost();
  }
};
