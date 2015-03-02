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
  bool _computeGradient;

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

  /* Compute the cost only. */
  double computeCost(const nvVecd &x);
	
  /* Method that should be overriden to provide the concrete implementation. */
  virtual double train(const nvVecd &initx, nvVecd &xresult);

  /* Debug method sued to compute numerical gradients. */
  void computeNumericalGradient(const nvVecd& x, nvVecd& grad, double eps = 1e-6);

protected:
  /* Method that should be overriden to provide the concrete implementation. */
  virtual void computeCost();

  /* method used to select the appropriate training implementation. */
  double dispatch_train(const nvTradeModelTraits &traits, const nvVecd &initx, nvVecd &xresult);

  /* Minimization with conjugate gradient descent. */
  double train_cg(const nvTradeModelTraits &traits, const nvVecd &initx, nvVecd &xresult);

  /* Train with simple gradient descent. */
  double train_gd(const nvTradeModelTraits &traits, const nvVecd &initx, nvVecd &xresult);

  /* Online training method. */
  double train_gd_online(const nvTradeModelTraits &traits, const nvVecd &initx, nvVecd &xresult);
};


//////////////////////////////////// implementation part ///////////////////////////
nvCostFunctionBase::nvCostFunctionBase(int dim)
  : _x(dim),
    _grad(dim),
    _computeGradient(true)
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

double nvCostFunctionBase::computeCost(const nvVecd &x)
{
  _x = x;
  // Disable computation of gradient for this run:
  _computeGradient = false;
  computeCost();
  // Restore computation of gradient:
  _computeGradient = true;
  return _cost;
}

void nvCostFunctionBase::computeCost()
{
  THROW("This method should be overriden.");
}

double nvCostFunctionBase::dispatch_train(const nvTradeModelTraits &traits, const nvVecd &initx, nvVecd &xresult)
{
  switch(traits.trainMode())
  {
  case TRAIN_BATCH_CONJUGATE_GRADIENT:
    return train_cg(traits,initx,xresult);
  case TRAIN_BATCH_GRADIENT_DESCENT:
    return train_gd(traits,initx,xresult);
  case TRAIN_STOCHASTIC_GRADIENT_DESCENT:
    return train_gd_online(traits,initx,xresult);
  }

  THROW("Unsupported train method: "<<(int)traits.trainMode());
  return 0.0;
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

double nvCostFunctionBase::train_gd(const nvTradeModelTraits &traits, const nvVecd &initx, nvVecd &xresult)
{
  // Number of epochs:
  int ne = traits.numEpochs(); 

  // learning rate:
  double rho = traits.learningRate();

  nvVecd x = initx;
  double cost;
  nvVecd grad;

  for(int i=0;i<ne;++i)
  {
    // compute the current gradient
    cost = computeCost(x,grad);
    logDEBUG("Cost at epoch "<<i<<": "<<cost);

    // Update the x vector:
    x -= grad * rho;
  }

  // Compute the final cost:
  cost = computeCost(x);
  logDEBUG("Final cost after training: "<<cost);

  // Now save the result:
  xresult = x;
  return cost;
}

double nvCostFunctionBase::train_gd_online(const nvTradeModelTraits &traits, const nvVecd &initx, nvVecd &xresult)
{
  return 0.0;
}

double nvCostFunctionBase::train(const nvVecd &initx, nvVecd &xresult)
{
  THROW("This method should be overriden.");
  return 0.0;
}

void nvCostFunctionBase::computeNumericalGradient(const nvVecd& x, nvVecd& grad, double eps = 1e-6)
{
  int num = (int)x.size();
  grad.resize(num);
  nvVecd perturb(num);

  for(int i=0;i<num;++i)
  {
    perturb.set(i,eps);
    
    double cost1 = computeCost(x-perturb);
    double cost2 = computeCost(x+perturb);
    
    grad.set(i,(cost2-cost1)/(2.0*eps));

    perturb.set(i,0.0);
  }
}
