/**
 * L-BFGS optimization parameters.
 *  Call lbfgs_parameter_init() function to initialize parameters to the
 *  default values.
 */
class LBFGSParameters
{
public:
  /**
   * The number of corrections to approximate the inverse hessian matrix.
   *  The L-BFGS routine stores the computation results of previous \ref m
   *  iterations to approximate the inverse hessian matrix of the current
   *  iteration. This parameter controls the size of the limited memories
   *  (corrections). The default value is \c 6. Values less than \c 3 are
   *  not recommended. Large values will result in excessive computing time.
   */
  int m;

  /**
   * Epsilon for convergence test.
   *  This parameter determines the accuracy with which the solution is to
   *  be found. A minimization terminates when
   *      ||g|| < \ref epsilon * max(1, ||x||),
   *  where ||.|| denotes the Euclidean (L2) norm. The default value is
   *  \c 1e-5.
   */
  double epsilon;

  /**
   * Distance for delta-based convergence test.
   *  This parameter determines the distance, in iterations, to compute
   *  the rate of decrease of the objective function. If the value of this
   *  parameter is zero, the library does not perform the delta-based
   *  convergence test. The default value is \c 0.
   */
  int past;

  /**
   * Delta for convergence test.
   *  This parameter determines the minimum rate of decrease of the
   *  objective function. The library stops iterations when the
   *  following condition is met:
   *      (f' - f) / f < \ref delta,
   *  where f' is the objective value of \ref past iterations ago, and f is
   *  the objective value of the current iteration.
   *  The default value is \c 0.
   */
  double delta;

  /**
   * The maximum number of iterations.
   *  The lbfgs() function terminates an optimization process with
   *  ::LBFGSERR_MAXIMUMITERATION status code when the iteration count
   *  exceedes this parameter. Setting this parameter to zero continues an
   *  optimization process until a convergence or error. The default value
   *  is \c 0.
   */
  int max_iterations;

  /**
   * The line search algorithm.
   *  This parameter specifies a line search algorithm to be used by the
   *  L-BFGS routine.
   */
  int linesearch;

  /**
   * The maximum number of trials for the line search.
   *  This parameter controls the number of function and gradients evaluations
   *  per iteration for the line search routine. The default value is \c 20.
   */
  int max_linesearch;

  /**
   * The minimum step of the line search routine.
   *  The default value is \c 1e-20. This value need not be modified unless
   *  the exponents are too large for the machine being used, or unless the
   *  problem is extremely badly scaled (in which case the exponents should
   *  be increased).
   */
  double min_step;

  /**
   * The maximum step of the line search.
   *  The default value is \c 1e+20. This value need not be modified unless
   *  the exponents are too large for the machine being used, or unless the
   *  problem is extremely badly scaled (in which case the exponents should
   *  be increased).
   */
  double max_step;

  /**
   * A parameter to control the accuracy of the line search routine.
   *  The default value is \c 1e-4. This parameter should be greater
   *  than zero and smaller than \c 0.5.
   */
  double ftol;

  /**
   * A coefficient for the Wolfe condition.
   *  This parameter is valid only when the backtracking line-search
   *  algorithm is used with the Wolfe condition,
   *  ::LBFGS_LINESEARCH_BACKTRACKING_STRONG_WOLFE or
   *  ::LBFGS_LINESEARCH_BACKTRACKING_WOLFE .
   *  The default value is \c 0.9. This parameter should be greater
   *  the \ref ftol parameter and smaller than \c 1.0.
   */
  double wolfe;

  /**
   * A parameter to control the accuracy of the line search routine.
   *  The default value is \c 0.9. If the function and gradient
   *  evaluations are inexpensive with respect to the cost of the
   *  iteration (which is sometimes the case when solving very large
   *  problems) it may be advantageous to set this parameter to a small
   *  value. A typical small value is \c 0.1. This parameter shuold be
   *  greater than the \ref ftol parameter (\c 1e-4) and smaller than
   *  \c 1.0.
   */
  double gtol;

  /**
   * The machine precision for floating-point values.
   *  This parameter must be a positive value set by a client program to
   *  estimate the machine precision. The line search routine will terminate
   *  with the status code (::LBFGSERR_ROUNDING_ERROR) if the relative width
   *  of the interval of uncertainty is less than this parameter.
   */
  double xtol;

  /**
   * Coeefficient for the L1 norm of variables.
   *  This parameter should be set to zero for standard minimization
   *  problems. Setting this parameter to a positive value activates
   *  Orthant-Wise Limited-memory Quasi-Newton (OWL-QN) method, which
   *  minimizes the objective function F(x) combined with the L1 norm |x|
   *  of the variables, {F(x) + C |x|}. This parameter is the coeefficient
   *  for the |x|, i.e., C. As the L1 norm |x| is not differentiable at
   *  zero, the library modifies function and gradient evaluations from
   *  a client program suitably; a client program thus have only to return
   *  the function value F(x) and gradients G(x) as usual. The default value
   *  is zero.
   */
  double orthantwise_c;

  /**
   * Start index for computing L1 norm of the variables.
   *  This parameter is valid only for OWL-QN method
   *  (i.e., \ref orthantwise_c != 0). This parameter b (0 <= b < N)
   *  specifies the index number from which the library computes the
   *  L1 norm of the variables x,
   *      |x| := |x_{b}| + |x_{b+1}| + ... + |x_{N}| .
   *  In other words, variables x_1, ..., x_{b-1} are not used for
   *  computing the L1 norm. Setting b (0 < b < N), one can protect
   *  variables, x_1, ..., x_{b-1} (e.g., a bias term of logistic
   *  regression) from being regularized. The default value is zero.
   */
  int orthantwise_start;

  /**
   * End index for computing L1 norm of the variables.
   *  This parameter is valid only for OWL-QN method
   *  (i.e., \ref orthantwise_c != 0). This parameter e (0 < e <= N)
   *  specifies the index number at which the library stops computing the
   *  L1 norm of the variables x,
   */
  int orthantwise_end;

  LBFGSParameters() : m(6), epsilon(1e-5), past(0), delta(1e-5),
    max_iterations(0), linesearch(LBFGS_LINESEARCH_DEFAULT), max_linesearch(40),
    min_step(1e-20), max_step(1e20), ftol(1e-4), wolfe(0.9), gtol(0.9),
    xtol(1.0e-16), orthantwise_c(0.0), orthantwise_start(0), orthantwise_end(-1)
  {
  }
};
