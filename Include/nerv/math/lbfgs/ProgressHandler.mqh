
#include <nerv/math/lbfgs/UserData.mqh>

class LBFGSProgressHandler
{
public:
  /**
   * Callback interface to receive the progress of the optimization process.
   *
   *  The lbfgs() function call this function for each iteration. Implementing
   *  this function, a client program can store or display the current progress
   *  of the optimization process.
   *
   *  @param  instance    The user data sent for lbfgs() function by the client.
   *  @param  x           The current values of variables.
   *  @param  g           The current gradient values of variables.
   *  @param  fx          The current value of the objective function.
   *  @param  xnorm       The Euclidean norm of the variables.
   *  @param  gnorm       The Euclidean norm of the gradients.
   *  @param  step        The line-search step used for this iteration.
   *  @param  n           The number of variables.
   *  @param  k           The iteration count.
   *  @param  ls          The number of evaluations called for this iteration.
   *  @retval int         Zero to continue the optimization process. Returning a
   *                      non-zero value will cancel the optimization process.
   */
  virtual int progress(LBFGSUserData *instance, const double &x[],
                       const double &grad[], const double fx,
                       const double xnorm, const double gnorm,
                       const double step, int n, int k, int ls)
  {
    logERROR("LBFGSProgressHandler::progress() should not be called.")
    return 0;
  };
};

class LBFGSDefaultProgressHandler : public LBFGSProgressHandler
{
public:
  /**
   * Callback interface to receive the progress of the optimization process.
   *
   *  The lbfgs() function call this function for each iteration. Implementing
   *  this function, a client program can store or display the current progress
   *  of the optimization process.
   *
   *  @param  instance    The user data sent for lbfgs() function by the client.
   *  @param  x           The current values of variables.
   *  @param  g           The current gradient values of variables.
   *  @param  fx          The current value of the objective function.
   *  @param  xnorm       The Euclidean norm of the variables.
   *  @param  gnorm       The Euclidean norm of the gradients.
   *  @param  step        The line-search step used for this iteration.
   *  @param  n           The number of variables.
   *  @param  k           The iteration count.
   *  @param  ls          The number of evaluations called for this iteration.
   *  @retval int         Zero to continue the optimization process. Returning a
   *                      non-zero value will cancel the optimization process.
   */
  virtual int progress(LBFGSUserData *instance, const double &x[],
                       const double &grad[], const double fx,
                       const double xnorm, const double gnorm,
                       const double step, int n, int k, int ls)
  {
    logDEBUG("Iteration "<<k<<": gnorm="<<gnorm<<", step="<<step<<", ls="<<ls<<", fx="<<fx);
    return 0;
  };
};
