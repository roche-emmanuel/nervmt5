#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include <nerv/trades.mqh>

class nvCostFunctionBase : public CNDimensional_Grad
{
protected:
  nvVecd _x;
  nvVecd _grad;
  double _cost;

  double _bestCost;
  nvVecd _bestX;

public:
  /* default constructor.*/
  nvCostFunctionBase(int dim);

  /* Main method used to pass the function value and gradient vector to the optimization procedure. */
  virtual void Grad(double &x[], double &func, double &grad[], CObject &obj);

  /* Retrieve the best cost and x parameter discovered so far. */
  double getBestCost(nvVecd &x) const;

  /* Actual method to reimplement to compute the cost and gradient data.
  This method must be re-implemented by derived classes.*/
  virtual void computeGradient(double &x[], double &func, double &grad[]);

  /* Reset the best x and cost found so far. */
  virtual void reset();

  /* Compute the cost and gradient to arrays. */
  double computeCost(double &x[], double &grad[]);

  /* Compute the cost and gradient to vectors. */
  double computeCost(const nvVecd &x, nvVecd &grad);

  /* Method that should be overriden to provide the concrete implementation. */
  virtual void computeCost();

	/* Minimization with conjugate gradient descent. */
	double train_cg(const nvTradeModelTraits &traits, const nvVecd &initx, nvVecd &xresult);
	
  /* Method that should be overriden to provide the concrete implementation. */
  virtual double train(const nvVecd &initx, nvVecd &xresult);
};


//////////////////////////////////// implementation part ///////////////////////////
nvCostFunctionBase::nvCostFunctionBase(int dim)
  : _x(dim),
    _grad(dim)
{
  reset();
}

void nvCostFunctionBase::reset()
{
  _bestCost = 1e10;
  _bestX.resize();
}

double nvCostFunctionBase::getBestCost(nvVecd &x) const
{
  x = _bestX;
  return _bestCost;
}

void nvCostFunctionBase::Grad(double &x[], double &func, double &grad[], CObject &obj)
{
  // Compute the gradient:
  func = computeCost(x, grad);

  if (func <= _bestCost)
  {
    _bestCost = func;
    _bestX = x;
  }
}

double nvCostFunctionBase::computeCost(double &x[], double &grad[])
{
  _x = x;
  computeCost();
  _grad.toArray(grad);
  return _cost;
}

double nvCostFunctionBase::computeCost(const nvVecd &x, nvVecd &grad)
{
  _x = x;
  computeCost();
  grad = _grad;
  return _cost;
}


void nvCostFunctionBase::computeCost()
{
  THROW("This method should be overriden.");
}

double nvCostFunctionBase::train_cg(const nvTradeModelTraits &traits, const nvVecd &initx, nvVecd &xresult)
{
  double x[];
  initx.toArray(x);

  CMinCGStateShell state;
  CAlglib::MinCGCreate(x, state);

  CAlglib::MinCGSetCond(state, traits.epsilonG(), traits.epsilonF(), traits.epsilonX(), traits.maxIterations());

  CNDimensional_Rep rep;

  CObject objdum;
  CAlglib::MinCGOptimize(state, THIS, rep, false, objdum);

  CMinCGReportShell res;
  CAlglib::MinCGResults(state, x, res);

  logDEBUG("Optimization done with best cost: " << _bestCost);
  xresult = x;
  return _bestCost;
}

double nvCostFunctionBase::train(const nvVecd &initx, nvVecd &xresult)
{
  THROW("This method should be overriden.");
  return 0.0;
}