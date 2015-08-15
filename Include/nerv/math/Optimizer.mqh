#include <nerv/core.mqh>
#include <nerv/math.mqh>

/*
Class: nvOptimizer

Base class used to implement an optimizer based on cost function optimization.
*/
class nvOptimizer : public CNDimensional_Grad
{
protected:
  double _bestCost;
  nvVecd _bestX;
  double _epsG;
  double _epsF;
  double _epsX;
  int _maxIters;

public:
  /*
    Class constructor.
  */
  nvOptimizer()
  {
    reset();
    setStopConditions(1e-10,0.0,0.0,30);
  }

  /*
    Copy constructor
  */
  nvOptimizer(const nvOptimizer& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvOptimizer& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvOptimizer()
  {
    // No op.
  }

  /*
  Function: Grad
  
  Method that will be called each time the cost function should be evaluated.
  */
  void Grad(double &x[],double &func,double &grad[],CObject &obj)
  {
    func = computeCost(x, grad);

    if (func <= _bestCost)
    {
      _bestCost = func;
      _bestX = x;
    }
  }

  /*
  Function: computeCost
  
  Method called to compute the actual cost from this cost function.
  This should be re-implemented by derived classes.
  */
  virtual double computeCost(double &x[], double &grad[])
  {
    // does nothing by default.
    return 0.0;
  }

  /*
  Function: getBestCost
  
  Retrieve the best cost and x parameter discovered so far.
  */
  double getBestCost(nvVecd& x)
  {
    x = _bestX;
    return _bestCost;    
  }

  /*
  Function: reset

  Reset the observed best cost and x parameters observed so far.
  */
  void reset()
  {
    _bestCost = 1e100;
    _bestX.resize();  
  }

  /*
  Function: setStopConditions
  
  Method called to set the stop condition for the minimizer.
  See: http://www.alglib.net/translator/man/manual.cpp.html#sub_minlbfgssetcond
  */
  void setStopConditions(double epsG, double epsF, double epsX, int maxIters)
  {
    _epsG = epsG;
    _epsF = epsF;
    _epsX = epsX;
    _maxIters = maxIters;
  }
  
  /*
  Function: optimize_cg
  
  Perform optimization using a conjugate gradient technique.

  The method will return the termination type
  */
  int optimize_cg(double &x[], double& cost)
  {
    CMinCGStateShell state;
    CAlglib::MinCGCreate(x, state);

    CAlglib::MinCGSetCond(state, _epsG, _epsF, _epsX, _maxIters);

    CNDimensional_Rep rep;

    CObject objdum;
    CAlglib::MinCGOptimize(state, THIS, rep, false, objdum);

    CMinCGReportShell res;
    CAlglib::MinCGResults(state, x, res);

    int ttype = res.GetTerminationType();

    logDEBUG("Optimization done with best cost: " << _bestCost
      <<", iteration count: "<<res.GetIterationsCount()
      <<", numFuncEvals: "<<res.GetNFev()
      <<", terminationType: "<<ttype);

    cost = _bestCost;

    return ttype;
  }

  /*
  Function: optimize_lbfgs
  
  Perform optimization using a L-BFGS technique.

  This method will return the termination type.
  */
  int optimize_lbfgs(double &x[], double& cost, int m=0)
  {
    int dim = ArraySize( x );
    if(m==0)
    {
      // Use all the dimensions available:
      m = dim;
    }

    // Ensure that m is smaller that the number of dimensions:
    CHECK_RET(m<=dim,-10,"Invalid value of M="<<m)
    
    CMinLBFGSStateShell state;
    CAlglib::MinLBFGSCreate(m, x, state);

    CAlglib::MinLBFGSSetCond(state, _epsG, _epsF, _epsX, _maxIters);

    CNDimensional_Rep rep;

    CObject objdum;
    CAlglib::MinLBFGSOptimize(state, THIS, rep, false, objdum);

    CMinLBFGSReportShell res;
    CAlglib::MinLBFGSResults(state, x, res);

    int ttype = res.GetTerminationType();

    logDEBUG("Optimization done with best cost: " << _bestCost
      <<", iteration count: "<<res.GetIterationsCount()
      <<", numFuncEvals: "<<res.GetNFev()
      <<", terminationType: "<<ttype);

    cost = _bestCost;

    return ttype;
  }
  
};
