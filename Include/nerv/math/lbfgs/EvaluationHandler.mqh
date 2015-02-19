
#include <nerv/math/lbfgs/UserData.mqh>

class LBFGSEvaluationHandler
{
public:

  /**
   * Callback interface to provide objective function and gradient evaluations.
   *
   *  The lbfgs() function call this function to obtain the values of objective
   *  function and its gradients when needed. A client program must implement
   *  this function to evaluate the values of the objective function and its
   *  gradients, given current values of variables.
   *
   *  @param  instance    The user data sent for lbfgs() function by the client.
   *  @param  x           The current values of variables.
   *  @param  g           The gradient vector. The callback function must compute
   *                      the gradient values for the current variables.
   *  @param  n           The number of variables.
   *  @param  step        The current step of the line search routine.
   *  @retval double The value of the objective function for the current
   *                          variables.
   */
  virtual double evaluate(LBFGSUserData *instance, const double &x[], double &grad[], int n, double step)
  {
    return 0.0;
  };
};
