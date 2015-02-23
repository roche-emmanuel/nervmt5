
#include <nerv/core.mqh>
#include <nerv/math.mqh>

class nvRRLModelBase : public nvObject
{
protected:
  // Training parameters:
  double _epsg;
  double _epsf;
  double _epsx;
  int _maxIts;

  double _rmean;
  double _rdev;

public:
  nvRRLModelBase(int maxIts = 250) :
    _rmean(0.0), _rdev(0.0),
    _maxIts(maxIts)
  {
    // Default training parameters:
    _epsg = 0.0000000001;
    _epsf = 0.0;
    _epsx = 0.0;
  }

  ~nvRRLModelBase()
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

  virtual double predict(nvVecd *rvec, double prevVal, double& signal)
  {
    return 0.0;
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

  virtual double train_cg(double tcost, double Fstart, double Fend, nvVecd* init_x, nvVecd *returns)
  {
    return 0.0;
  }
};
