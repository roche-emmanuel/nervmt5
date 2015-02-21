
#include <nerv/core.mqh>
#include <nerv/math.mqh>

double rrlCostFunction(nvVecd *nrets, nvVecd *returns, double tcost, nvVecd *grad, nvVecd *theta)
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
    Ft = nv_tanh(params * theta);
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

class nvRRLEvaluator : public CNDimensional_Grad
{
protected:
  nvVecd _returns;
  nvVecd _nrets;

  nvVecd _grad;
  nvVecd _theta;
  double _tcost;
  
  double _bestCost;
  nvVecd _bestTheta;

public:
  nvRRLEvaluator(double tcost, nvVecd* returns, nvVecd* nretsvec = NULL) : _bestCost(1e10) {

    _returns = returns;

    if (nretsvec != NULL)
    {
      _nrets = nretsvec;
    }
    else
    {
      _nrets = returns.stdnormalize();
    }

    _tcost = tcost;
  }

  virtual void Grad(double &x[],double &func,double &grad[],CObject &obj)
  {
    _theta = x;
    //logDEBUG("Theta: "<<_theta);
    func = rrlCostFunction(GetPointer(_nrets),GetPointer(_returns),_tcost,GetPointer(_grad),GetPointer(_theta));
    //logDEBUG("Computed cost: "<<func);
    _grad.toArray(grad);

    if(func<=_bestCost) {
      _bestCost = func;
      _bestTheta = x;    
    }
  };

  double getBestCost() const
  {
    return _bestCost;
  }

  nvVecd* getBestTheta() const
  {
    return GetPointer(_bestTheta);
  }  
};

class nvRRLModel : public nvObject
{
protected:
  // Number of return inputs:
  uint _numInputs;

  // max norm allowed for theta vector:
  double _maxNorm;

  // Theta parameters:
  nvVecd _theta;

  // params used for evaluation:
  nvVecd _params;

  bool _normalizeInputs;

  // Training parameters:
  double _epsg;
  double _epsf;
  double _epsx;
  int _maxIts;

  double _rmean;
  double _rdev;

public:
  nvRRLModel(uint num, int maxIts = 250) : _params(num+2), _theta(num+2),
    _rmean(0.0), _rdev(0.0),
    _maxIts(maxIts)
  {
    _numInputs = num;
    _maxNorm = 2.0;
    _normalizeInputs = true;

    // Prepare the vector containing the theta values:
    // We need 2 additional coeffs for the u and w coeffs
    //nvVecd initial_theta(_numInputs + 2, 1.0);
    _theta.fill(1.0);

    // generate initial random coefficients:
    //_theta.randomize(-1.0, 1.0);
    //_theta.fill(1.0); // Initialize with 1.0.
    checkNorm();

    //logDEBUG("Initial theta vector is: " << _theta);

    // Default training parameters:
    _epsg = 0.0000000001;
    //_epsg = 0.0000001;
    _epsf = 0.0;
    _epsx = 0.0;
  }

  ~nvRRLModel()
  {
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

  double predict(nvVecd *rvec, double Ft_1)
  {
    _params.set(0,1.0);
    _params.set(1,Ft_1);
    _params.set(2,(rvec-_rmean)/_rdev);

    double val = _theta * _params;
    //logDEBUG("Theta vector: "<<_theta);
    //logDEBUG("Param vector: "<<params);
    //logDEBUG("Pre tanh value: "<<val);
    return nv_tanh(val);
  }

  void setMaxIterations(int num)
  {
    _maxIts = num;
  }

  void setTrainingParams(double epsg, double epsf, double epsx, int maxits)
  {
    _epsg = epsg;
    _epsf = epsf;
    _epsx = epsx;
    _maxIts = maxits;
  }

  double train(double tcost, nvVecd *returns)
  {
    return train_cg(tcost,GetPointer(_theta),returns);
  }

  double train_cg(double tcost, nvVecd* theta, nvVecd *returns, nvVecd *nretsvec = NULL)
  {
    // Prepare the training with MinCG:
    double x[];
    theta.toArray(x);

    CMinCGStateShell state;
    CAlglib::MinCGCreate(x,state);

    CAlglib::MinCGSetCond(state, _epsg, _epsf, _epsx, _maxIts);

    nvRRLEvaluator ev(tcost,returns,nretsvec);
    CNDimensional_Rep rep;

    CObject objdum;
    CAlglib::MinCGOptimize(state,ev,rep,false,objdum);

    CMinCGReportShell res;
    CAlglib::MinCGResults(state, x, res);
    
    //logDEBUG("Optimization done with best cost: "<< ev.getBestCost())
    _theta = x;
    _rmean = returns.mean();
    _rdev = returns.deviation();

    //logDEBUG("Trained theta: "<<_theta);
    //logDEBUG("rmean="<<_rmean<<", rdev="<<_rdev);

    //nvVecd bestTheta = ev.getBestTheta();
    //CHECK(bestTheta==_theta,"Mismatch in theta vectors: "<<_theta<<"!="<<bestTheta);

    return ev.getBestCost();
  }
};
