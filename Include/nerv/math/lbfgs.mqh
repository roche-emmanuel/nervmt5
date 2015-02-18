/*
 *      C library of Limited memory BFGS (L-BFGS).
 *
 * Copyright (c) 1990, Jorge Nocedal
 * Copyright (c) 2007-2010 Naoaki Okazaki
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */



/**
 * Return values of lbfgs().
 *
 *  Roughly speaking, a negative value indicates an error.
 */
enum
{
  /** L-BFGS reaches convergence. */
  LBFGS_SUCCESS = 0,
  LBFGS_CONVERGENCE = 0,
  LBFGS_STOP,
  /** The initial variables already minimize the objective function. */
  LBFGS_ALREADY_MINIMIZED,

  /** Unknown error. */
  LBFGSERR_UNKNOWNERROR = -1024,
  /** Logic error. */
  LBFGSERR_LOGICERROR,
  /** Insufficient memory. */
  LBFGSERR_OUTOFMEMORY,
  /** The minimization process has been canceled. */
  LBFGSERR_CANCELED,
  /** Invalid number of variables specified. */
  LBFGSERR_INVALID_N,
  /** Invalid number of variables (for SSE) specified. */
  LBFGSERR_INVALID_N_SSE,
  /** The array x must be aligned to 16 (for SSE). */
  LBFGSERR_INVALID_X_SSE,
  /** Invalid parameter LBGFSParameters::epsilon specified. */
  LBFGSERR_INVALID_EPSILON,
  /** Invalid parameter LBGFSParameters::past specified. */
  LBFGSERR_INVALID_TESTPERIOD,
  /** Invalid parameter LBGFSParameters::delta specified. */
  LBFGSERR_INVALID_DELTA,
  /** Invalid parameter LBGFSParameters::linesearch specified. */
  LBFGSERR_INVALID_LINESEARCH,
  /** Invalid parameter LBGFSParameters::max_step specified. */
  LBFGSERR_INVALID_MINSTEP,
  /** Invalid parameter LBGFSParameters::max_step specified. */
  LBFGSERR_INVALID_MAXSTEP,
  /** Invalid parameter LBGFSParameters::ftol specified. */
  LBFGSERR_INVALID_FTOL,
  /** Invalid parameter LBGFSParameters::wolfe specified. */
  LBFGSERR_INVALID_WOLFE,
  /** Invalid parameter LBGFSParameters::gtol specified. */
  LBFGSERR_INVALID_GTOL,
  /** Invalid parameter LBGFSParameters::xtol specified. */
  LBFGSERR_INVALID_XTOL,
  /** Invalid parameter LBGFSParameters::max_linesearch specified. */
  LBFGSERR_INVALID_MAXLINESEARCH,
  /** Invalid parameter LBGFSParameters::orthantwise_c specified. */
  LBFGSERR_INVALID_ORTHANTWISE,
  /** Invalid parameter LBGFSParameters::orthantwise_start specified. */
  LBFGSERR_INVALID_ORTHANTWISE_START,
  /** Invalid parameter LBGFSParameters::orthantwise_end specified. */
  LBFGSERR_INVALID_ORTHANTWISE_END,
  /** The line-search step went out of the interval of uncertainty. */
  LBFGSERR_OUTOFINTERVAL,
  /** A logic error occurred; alternatively, the interval of uncertainty
      became too small. */
  LBFGSERR_INCORRECT_TMINMAX,
  /** A rounding error occurred; alternatively, no line-search step
      satisfies the sufficient decrease and curvature conditions. */
  LBFGSERR_ROUNDING_ERROR,
  /** The line-search step became smaller than LBGFSParameters::min_step. */
  LBFGSERR_MINIMUMSTEP,
  /** The line-search step became larger than LBGFSParameters::max_step. */
  LBFGSERR_MAXIMUMSTEP,
  /** The line-search routine reaches the maximum number of evaluations. */
  LBFGSERR_MAXIMUMLINESEARCH,
  /** The algorithm routine reaches the maximum number of iterations. */
  LBFGSERR_MAXIMUMITERATION,
  /** Relative width of the interval of uncertainty is at most
      LBGFSParameters::xtol. */
  LBFGSERR_WIDTHTOOSMALL,
  /** A logic error (negative line-search step) occurred. */
  LBFGSERR_INVALIDPARAMETERS,
  /** The current search direction increases the objective function value. */
  LBFGSERR_INCREASEGRADIENT,
};

/**
 * Line search algorithms.
 */
enum
{
  /** The default algorithm (MoreThuente method). */
  LBFGS_LINESEARCH_DEFAULT = 0,
  /** MoreThuente method proposd by More and Thuente. */
  LBFGS_LINESEARCH_MORETHUENTE = 0,
  /**
   * Backtracking method with the Armijo condition.
   *  The backtracking method finds the step length such that it satisfies
   *  the sufficient decrease (Armijo) condition,
   *    - f(x + a * d) <= f(x) + LBGFSParameters::ftol * a * g(x)^T d,
   *
   *  where x is the current point, d is the current search direction, and
   *  a is the step length.
   */
  LBFGS_LINESEARCH_BACKTRACKING_ARMIJO = 1,
  /** The backtracking method with the defualt (regular Wolfe) condition. */
  LBFGS_LINESEARCH_BACKTRACKING = 2,
  /**
   * Backtracking method with regular Wolfe condition.
   *  The backtracking method finds the step length such that it satisfies
   *  both the Armijo condition (LBFGS_LINESEARCH_BACKTRACKING_ARMIJO)
   *  and the curvature condition,
   *    - g(x + a * d)^T d >= LBGFSParameters::wolfe * g(x)^T d,
   *
   *  where x is the current point, d is the current search direction, and
   *  a is the step length.
   */
  LBFGS_LINESEARCH_BACKTRACKING_WOLFE = 2,
  /**
   * Backtracking method with strong Wolfe condition.
   *  The backtracking method finds the step length such that it satisfies
   *  both the Armijo condition (LBFGS_LINESEARCH_BACKTRACKING_ARMIJO)
   *  and the following condition,
   *    - |g(x + a * d)^T d| <= LBGFSParameters::wolfe * |g(x)^T d|,
   *
   *  where x is the current point, d is the current search direction, and
   *  a is the step length.
   */
  LBFGS_LINESEARCH_BACKTRACKING_STRONG_WOLFE = 3,
};

/**
 * L-BFGS optimization parameters.
 *  Call lbfgs_parameter_init() function to initialize parameters to the
 *  default values.
 */
class LBGFSParameters
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

  LBGFSParameters() : m(6), epsilon(1e-5), past(0), delta(1e-5),
    max_iterations(0), linesearch(LBFGS_LINESEARCH_DEFAULT), max_linesearch(40),
    min_step(1e-20), max_step(1e20), ftol(1e-4), wolfe(0.9), gtol(0.9),
    xtol(1.0e-16), orthantwise_c(0.0), orthantwise_start(0), orthantwise_end(-1)
  {
  }
};

class LBGFSUserData
{

};

class LBGFSEvaluationHandler
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
  virtual double evaluate(LBGFSUserData *instance, const double &x[], double &grad[], int n, double step)
  {
    return 0.0;
  };
};

class LBGFSProgressHandler
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
  virtual int progress(LBGFSUserData *instance, const double &x[],
                       const double &grad[], const double fx,
                       const double xnorm, const double gnorm,
                       const double step, int n, int k, int ls)
  {
    return 0;
  };
};

struct callback_data_t
{
  int n;
  LBGFSUserData *instance;
  LBGFSEvaluationHandler *proc_evaluate;
  LBGFSProgressHandler *proc_progress;
};

struct iteration_data_t
{
  double alpha;
  double s[];     /* [n] */
  double y[];     /* [n] */
  double ys;     /* vecdot(y, s) */
};

#include "lbfgs/LineSearchMorethuente.mqh"
#include "lbfgs/LineSearchBacktracking_owlqn.mqh"
#include "lbfgs/LineSearchBacktracking.mqh"

/*
A user must implement a function compatible with ::lbfgs_evaluate_t (evaluation
callback) and pass the pointer to the callback function to lbfgs() arguments.
Similarly, a user can implement a function compatible with ::lbfgs_progress_t
(progress callback) to obtain the current progress (e.g., variables, function
value, ||G||, etc) and to cancel the iteration process if necessary.
Implementation of a progress callback is optional: a user can pass \c NULL if
progress notification is not necessary.

In addition, a user must preserve two requirements:
    - The number of variables must be multiples of 16 (this is not 4).
    - The memory block of variable array ::x must be aligned to 16.

This algorithm terminates an optimization
when:

    ||G|| < \epsilon \cdot \max(1, ||x||) .

In this formula, ||.|| denotes the Euclidean norm.
*/

/**
 * Start a L-BFGS optimization.
 *
 *  @param  n           The number of variables.
 *  @param  x           The array of variables. A client program can set
 *                      default values for the optimization and receive the
 *                      optimization result through this array. This array
 *                      must be allocated by ::lbfgs_malloc function
 *                      for libLBFGS built with SSE/SSE2 optimization routine
 *                      enabled. The library built without SSE/SSE2
 *                      optimization does not have such a requirement.
 *  @param  ptr_fx      The pointer to the variable that receives the final
 *                      value of the objective function for the variables.
 *                      This argument can be set to \c NULL if the final
 *                      value of the objective function is unnecessary.
 *  @param  proc_evaluate   The callback function to provide function and
 *                          gradient evaluations given a current values of
 *                          variables. A client program must implement a
 *                          callback function compatible with \ref
 *                          lbfgs_evaluate_t and pass the pointer to the
 *                          callback function.
 *  @param  proc_progress   The callback function to receive the progress
 *                          (the number of iterations, the current value of
 *                          the objective function) of the minimization
 *                          process. This argument can be set to \c NULL if
 *                          a progress report is unnecessary.
 *  @param  instance    A user data for the client program. The callback
 *                      functions will receive the value of this argument.
 *  @param  param       The pointer to a structure representing parameters for
 *                      L-BFGS optimization. A client program can set this
 *                      parameter to \c NULL to use the default parameters.
 *                      Call lbfgs_parameter_init() function to fill a
 *                      structure with the default values.
 *  @retval int         The status code. This function returns zero if the
 *                      minimization process terminates without an error. A
 *                      non-zero value indicates an error.
 */
int lbfgs(
  int n,
  double &x[],
  double &ptr_fx[],
  LBGFSEvaluationHandler *proc_evaluate,
  LBGFSProgressHandler *proc_progress,
  LBGFSUserData *instance,
  LBGFSParameters *_param = NULL
)
{
  int ret = LBFGS_SUCCESS;
  int i, j, k, ls, end, bound;
  double step;

  /* Constant parameters and their default values. */
  LBGFSParameters defaultParams;
  LBGFSParameters *param = _param != NULL ? _param : GetPointer(defaultParams);
  const int m = param.m;

  double xp[];
  double g[], gp[], pg[];
  double d[], w[], pf[];
  iteration_data_t lm[]; //, *it = NULL;
  double ys, yy;
  double xnorm, gnorm, beta;
  double fx = 0.0;
  double rate = 0.0;
  LineSearchMorethuente ls_m;
  LineSearchBacktracking_owlqn ls_bt_owlqn;
  LineSearchBacktracking ls_bt;

  LBFGSLineSearch *linesearch = GetPointer(ls_m);

  /* Construct a callback data. */
  callback_data_t cd;
  cd.n = n;
  cd.instance = instance;
  cd.proc_evaluate = proc_evaluate;
  cd.proc_progress = proc_progress;


  /* Check the input parameters for errors. */
  if (n <= 0)
  {
    return LBFGSERR_INVALID_N;
  }
  if (param.epsilon < 0.)
  {
    return LBFGSERR_INVALID_EPSILON;
  }
  if (param.past < 0)
  {
    return LBFGSERR_INVALID_TESTPERIOD;
  }
  if (param.delta < 0.)
  {
    return LBFGSERR_INVALID_DELTA;
  }
  if (param.min_step < 0.)
  {
    return LBFGSERR_INVALID_MINSTEP;
  }
  if (param.max_step < param.min_step)
  {
    return LBFGSERR_INVALID_MAXSTEP;
  }
  if (param.ftol < 0.)
  {
    return LBFGSERR_INVALID_FTOL;
  }
  if (param.linesearch == LBFGS_LINESEARCH_BACKTRACKING_WOLFE ||
      param.linesearch == LBFGS_LINESEARCH_BACKTRACKING_STRONG_WOLFE)
  {
    if (param.wolfe <= param.ftol || 1. <= param.wolfe)
    {
      return LBFGSERR_INVALID_WOLFE;
    }
  }
  if (param.gtol < 0.)
  {
    return LBFGSERR_INVALID_GTOL;
  }
  if (param.xtol < 0.)
  {
    return LBFGSERR_INVALID_XTOL;
  }
  if (param.max_linesearch <= 0)
  {
    return LBFGSERR_INVALID_MAXLINESEARCH;
  }
  if (param.orthantwise_c < 0.)
  {
    return LBFGSERR_INVALID_ORTHANTWISE;
  }
  if (param.orthantwise_start < 0 || n < param.orthantwise_start)
  {
    return LBFGSERR_INVALID_ORTHANTWISE_START;
  }
  if (param.orthantwise_end < 0)
  {
    param.orthantwise_end = n;
  }
  if (n < param.orthantwise_end)
  {
    return LBFGSERR_INVALID_ORTHANTWISE_END;
  }
  if (param.orthantwise_c != 0.)
  {
    switch (param.linesearch)
    {
    case LBFGS_LINESEARCH_BACKTRACKING:
      linesearch = GetPointer(ls_bt_owlqn) ;
      break;
    default:
      /* Only the backtracking method is available. */
      return LBFGSERR_INVALID_LINESEARCH;
    }
  }
  else
  {
    switch (param.linesearch)
    {
    case LBFGS_LINESEARCH_MORETHUENTE:
      linesearch = GetPointer(ls_m);
      break;
    case LBFGS_LINESEARCH_BACKTRACKING_ARMIJO:
    case LBFGS_LINESEARCH_BACKTRACKING_WOLFE:
    case LBFGS_LINESEARCH_BACKTRACKING_STRONG_WOLFE:
      linesearch = GetPointer(ls_bt);
      break;
    default:
      return LBFGSERR_INVALID_LINESEARCH;
    }
  }


  /* Allocate working space. */
  CHECK(ArrayResize(xp, n) == n, "Cannot allocate vector");
  CHECK(ArrayResize(g, n) == n, "Cannot allocate vector");
  CHECK(ArrayResize(gp, n) == n, "Cannot allocate vector");
  CHECK(ArrayResize(d, n) == n, "Cannot allocate vector");
  CHECK(ArrayResize(w, n) == n, "Cannot allocate vector");

  if (param.orthantwise_c != 0.)
  {
    /* Allocate working space for OW-LQN. */
    CHECK(ArrayResize(pg, n) == n, "Cannot allocate vector");
  }

  /* Allocate limited memory storage. */
  CHECK(ArrayResize(lm, m) == m, "Cannot allocate lm array.");

  /* Initialize the limited memory. */
  for (i = 0; i < m; ++i)
  {
    lm[i].alpha = 0;
    lm[i].ys = 0;
    CHECK(ArrayResize(lm[i].s, n) == n, "Cannot allocate vector");
    CHECK(ArrayResize(lm[i].y, n) == n, "Cannot allocate vector");
  }

  /* Allocate an array for storing previous values of the objective function. */
  if (0 < param.past)
  {
    CHECK(ArrayResize(pf, param.past) == param.past, "Cannot allocate vector");
  }

  /* Evaluate the function value and its gradient. */
  fx = cd.proc_evaluate.evaluate(cd.instance, x, g, cd.n, 0);
  if (0. != param.orthantwise_c)
  {
    /* Compute the L1 norm of the variable and add it to the object value. */
    xnorm = owlqn_x1norm(x, param.orthantwise_start, param.orthantwise_end);
    fx += xnorm * param.orthantwise_c;
    owlqn_pseudo_gradient(
      pg, x, g, n,
      param.orthantwise_c, param.orthantwise_start, param.orthantwise_end
    );
  }

  /* Store the initial value of the objective function. */
  SET_OPTIONAL(pf, fx);

  /*
      Compute the direction;
      we assume the initial hessian matrix H_0 as the identity matrix.
   */
  if (param.orthantwise_c == 0.)
  {
    vecncpy(d, g, n);
  }
  else
  {
    vecncpy(d, pg, n);
  }

  /*
     Make sure that the initial variables are not a minimizer.
   */
  xnorm = vec2norm(x, n);
  if (param.orthantwise_c == 0.)
  {
    gnorm = vec2norm(g, n);
  }
  else
  {
    gnorm = vec2norm(pg, n);
  }
  if (xnorm < 1.0) xnorm = 1.0;
  if (gnorm / xnorm <= param.epsilon)
  {
    LBFGS_EXIT(LBFGS_ALREADY_MINIMIZED);
  }

  /* Compute the initial step:
      step = 1.0 / sqrt(vecdot(d, d, n))
   */
  step = vec2norminv(d, n);

  k = 1;
  end = 0;

  for (;;)
  {
    /* Store the current position and gradient vectors. */
    veccpy(xp, x, n);
    veccpy(gp, g, n);

    /* Search for an optimal step. */
    if (param.orthantwise_c == 0.)
    {
      ls = linesearch.process(n, x, fx, g, d, step, xp, gp, w, cd, param);
    }
    else
    {
      ls = linesearch.process(n, x, fx, g, d, step, xp, pg, w, cd, param);
      owlqn_pseudo_gradient(
        pg, x, g, n,
        param.orthantwise_c, param.orthantwise_start, param.orthantwise_end
      );
    }
    if (ls < 0)
    {
      /* Revert to the previous point. */
      veccpy(x, xp, n);
      veccpy(g, gp, n);
      LBFGS_EXIT(ls);
    }

    /* Compute x and g norms. */
    xnorm = vec2norm(x, n);
    if (param.orthantwise_c == 0.)
    {
      gnorm = vec2norm(g, n);
    }
    else
    {
      gnorm = vec2norm(pg, n);
    }

    /* Report the progress. */
    if (cd.proc_progress != NULL)
    {
      ret = cd.proc_progress.progress(cd.instance, x, g, fx, xnorm, gnorm, step, cd.n, k, ls);
      if (ret)
      {
        LBFGS_EXIT(ret);
      }
    }

    /*
        Convergence test.
        The criterion is given by the following formula:
            |g(x)| / \max(1, |x|) < \epsilon
     */
    if (xnorm < 1.0) xnorm = 1.0;
    if (gnorm / xnorm <= param.epsilon)
    {
      /* Convergence. */
      ret = LBFGS_SUCCESS;
      break;
    }

    /*
        Test for stopping criterion.
        The criterion is given by the following formula:
            (f(past_x) - f(x)) / f(x) < \delta
     */
    if (ArraySize(pf) > 0)
    {
      /* We don't test the stopping criterion while k < past. */
      if (param.past <= k)
      {
        /* Compute the relative improvement from the past. */
        rate = (pf[k % param.past] - fx) / fx;

        /* The stopping criterion. */
        if (rate < param.delta)
        {
          ret = LBFGS_STOP;
          break;
        }
      }

      /* Store the current value of the objective function. */
      pf[k % param.past] = fx;
    }

    if (param.max_iterations != 0 && param.max_iterations < k + 1)
    {
      /* Maximum number of iterations. */
      ret = LBFGSERR_MAXIMUMITERATION;
      break;
    }

    /*
        Update vectors s and y:
            s_{k+1} = x_{k+1} - x_{k} = \step * d_{k}.
            y_{k+1} = g_{k+1} - g_{k}.
     */
    vecdiff(lm[end].s, x, xp, n);
    vecdiff(lm[end].y, g, gp, n);

    /*
        Compute scalars ys and yy:
            ys = y^t \cdot s = 1 / \rho.
            yy = y^t \cdot y.
        Notice that yy is used for scaling the hessian matrix H_0 (Cholesky factor).
     */
    ys = vecdot(lm[end].y, lm[end].s, n);
    yy = vecdot(lm[end].y, lm[end].y, n);
    lm[end].ys = ys;


    /*
        Recursive formula to compute dir = -(H \cdot g).
            This is described in page 779 of:
            Jorge Nocedal.
            Updating Quasi-Newton Matrices with Limited Storage.
            Mathematics of Computation, Vol. 35, No. 151,
            pp. 773--782, 1980.
     */
    bound = (m <= k) ? m : k;
    ++k;
    end = (end + 1) % m;

    /* Compute the steepest direction. */
    if (param.orthantwise_c == 0.)
    {
      /* Compute the negative of gradients. */
      vecncpy(d, g, n);
    }
    else
    {
      vecncpy(d, pg, n);
    }

    j = end;
    for (i = 0; i < bound; ++i)
    {
      j = (j + m - 1) % m;    /* if (--j == -1) j = m-1; */
      /* \alpha_{j} = \rho_{j} s^{t}_{j} \cdot q_{k+1}. */
      lm[j].alpha = vecdot(lm[j].s, d, n);
      lm[j].alpha /= lm[j].ys;
      /* q_{i} = q_{i+1} - \alpha_{i} y_{i}. */
      vecadd(d, lm[j].y, -lm[j].alpha, n);
    }

    vecscale(d, ys / yy, n);

    for (i = 0; i < bound; ++i)
    {
      /* \beta_{j} = \rho_{j} y^t_{j} \cdot \gamma_{i}. */
      beta = vecdot(lm[j].y, d, n);
      beta /= lm[j].ys;
      /* \gamma_{i+1} = \gamma_{i} + (\alpha_{j} - \beta_{j}) s_{j}. */
      vecadd(d, lm[j].s, lm[j].alpha - beta, n);
      j = (j + 1) % m;        /* if (++j == m) j = 0; */
    }

    /*
        Constrain the search direction for orthant-wise updates.
     */
    if (param.orthantwise_c != 0.)
    {
      for (i = param.orthantwise_start; i < param.orthantwise_end; ++i)
      {
        if (d[i] * pg[i] >= 0)
        {
          d[i] = 0;
        }
      }
    }

    /*
        Now the search direction d is ready. We try step = 1 first.
     */
    step = 1.0;
  }

  SET_OPTIONAL(ptr_fx,fx);
  return ret;
}
