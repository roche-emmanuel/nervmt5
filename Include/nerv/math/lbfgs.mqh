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
  /** Invalid parameter LBFGSParameters::epsilon specified. */
  LBFGSERR_INVALID_EPSILON,
  /** Invalid parameter LBFGSParameters::past specified. */
  LBFGSERR_INVALID_TESTPERIOD,
  /** Invalid parameter LBFGSParameters::delta specified. */
  LBFGSERR_INVALID_DELTA,
  /** Invalid parameter LBFGSParameters::linesearch specified. */
  LBFGSERR_INVALID_LINESEARCH,
  /** Invalid parameter LBFGSParameters::max_step specified. */
  LBFGSERR_INVALID_MINSTEP,
  /** Invalid parameter LBFGSParameters::max_step specified. */
  LBFGSERR_INVALID_MAXSTEP,
  /** Invalid parameter LBFGSParameters::ftol specified. */
  LBFGSERR_INVALID_FTOL,
  /** Invalid parameter LBFGSParameters::wolfe specified. */
  LBFGSERR_INVALID_WOLFE,
  /** Invalid parameter LBFGSParameters::gtol specified. */
  LBFGSERR_INVALID_GTOL,
  /** Invalid parameter LBFGSParameters::xtol specified. */
  LBFGSERR_INVALID_XTOL,
  /** Invalid parameter LBFGSParameters::max_linesearch specified. */
  LBFGSERR_INVALID_MAXLINESEARCH,
  /** Invalid parameter LBFGSParameters::orthantwise_c specified. */
  LBFGSERR_INVALID_ORTHANTWISE,
  /** Invalid parameter LBFGSParameters::orthantwise_start specified. */
  LBFGSERR_INVALID_ORTHANTWISE_START,
  /** Invalid parameter LBFGSParameters::orthantwise_end specified. */
  LBFGSERR_INVALID_ORTHANTWISE_END,
  /** The line-search step went out of the interval of uncertainty. */
  LBFGSERR_OUTOFINTERVAL,
  /** A logic error occurred; alternatively, the interval of uncertainty
      became too small. */
  LBFGSERR_INCORRECT_TMINMAX,
  /** A rounding error occurred; alternatively, no line-search step
      satisfies the sufficient decrease and curvature conditions. */
  LBFGSERR_ROUNDING_ERROR,
  /** The line-search step became smaller than LBFGSParameters::min_step. */
  LBFGSERR_MINIMUMSTEP,
  /** The line-search step became larger than LBFGSParameters::max_step. */
  LBFGSERR_MAXIMUMSTEP,
  /** The line-search routine reaches the maximum number of evaluations. */
  LBFGSERR_MAXIMUMLINESEARCH,
  /** The algorithm routine reaches the maximum number of iterations. */
  LBFGSERR_MAXIMUMITERATION,
  /** Relative width of the interval of uncertainty is at most
      LBFGSParameters::xtol. */
  LBFGSERR_WIDTHTOOSMALL,
  /** A logic error (negative line-search step) occurred. */
  LBFGSERR_INVALIDPARAMETERS,
  /** The current search direction increases the objective function value. */
  LBFGSERR_INCREASEGRADIENT,
};

string lbfgs_code_string(int code)
{
  switch(code)
  {
  /** L-BFGS reaches convergence. */
  case LBFGS_SUCCESS : 
    return "LBFGS_SUCCESS";
  case LBFGS_STOP : 
    return "LBFGS_STOP";
  /** The initial variables already minimize the objective function. */
  case LBFGS_ALREADY_MINIMIZED : 
    return "LBFGS_ALREADY_MINIMIZED";

  /** Unknown error. */
  case LBFGSERR_UNKNOWNERROR: 
    return "LBFGSERR_UNKNOWNERROR";
  /** Logic error. */
  case LBFGSERR_LOGICERROR: 
    return "LBFGSERR_LOGICERROR";
  /** Insufficient memory. */
  case LBFGSERR_OUTOFMEMORY: 
    return "LBFGSERR_OUTOFMEMORY";
  /** The minimization process has been canceled. */
  case LBFGSERR_CANCELED: 
    return "LBFGSERR_CANCELED";
  /** Invalid number of variables specified. */
  case LBFGSERR_INVALID_N: 
    return "LBFGSERR_INVALID_N";
  /** Invalid number of variables (for SSE) specified. */
  case LBFGSERR_INVALID_N_SSE: 
    return "LBFGSERR_INVALID_N_SSE";
  /** The array x must be aligned to 16 (for SSE). */
  case LBFGSERR_INVALID_X_SSE: 
    return "LBFGSERR_INVALID_X_SSE";
  /** Invalid parameter LBFGSParameters::epsilon specified. */
  case LBFGSERR_INVALID_EPSILON: 
    return "LBFGSERR_INVALID_EPSILON";
  /** Invalid parameter LBFGSParameters::past specified. */
  case LBFGSERR_INVALID_TESTPERIOD: 
    return "LBFGSERR_INVALID_TESTPERIOD";
  /** Invalid parameter LBFGSParameters::delta specified. */
  case LBFGSERR_INVALID_DELTA: 
    return "LBFGSERR_INVALID_DELTA";
  /** Invalid parameter LBFGSParameters::linesearch specified. */
  case LBFGSERR_INVALID_LINESEARCH: 
    return "LBFGSERR_INVALID_LINESEARCH";
  /** Invalid parameter LBFGSParameters::max_step specified. */
  case LBFGSERR_INVALID_MINSTEP: 
    return "LBFGSERR_INVALID_MINSTEP";
  /** Invalid parameter LBFGSParameters::max_step specified. */
  case LBFGSERR_INVALID_MAXSTEP: 
    return "LBFGSERR_INVALID_MAXSTEP";
  /** Invalid parameter LBFGSParameters::ftol specified. */
  case LBFGSERR_INVALID_FTOL: 
    return "LBFGSERR_INVALID_FTOL";
  /** Invalid parameter LBFGSParameters::wolfe specified. */
  case LBFGSERR_INVALID_WOLFE: 
    return "LBFGSERR_INVALID_WOLFE";
  /** Invalid parameter LBFGSParameters::gtol specified. */
  case LBFGSERR_INVALID_GTOL: 
    return "LBFGSERR_INVALID_GTOL";
  /** Invalid parameter LBFGSParameters::xtol specified. */
  case LBFGSERR_INVALID_XTOL: 
    return "LBFGSERR_INVALID_XTOL";
  /** Invalid parameter LBFGSParameters::max_linesearch specified. */
  case LBFGSERR_INVALID_MAXLINESEARCH: 
    return "LBFGSERR_INVALID_MAXLINESEARCH";
  /** Invalid parameter LBFGSParameters::orthantwise_c specified. */
  case LBFGSERR_INVALID_ORTHANTWISE: 
    return "LBFGSERR_INVALID_ORTHANTWISE";
  /** Invalid parameter LBFGSParameters::orthantwise_start specified. */
  case LBFGSERR_INVALID_ORTHANTWISE_START: 
    return "LBFGSERR_INVALID_ORTHANTWISE_START";
  /** Invalid parameter LBFGSParameters::orthantwise_end specified. */
  case LBFGSERR_INVALID_ORTHANTWISE_END: 
    return "LBFGSERR_INVALID_ORTHANTWISE_END";
  /** The line-search step went out of the interval of uncertainty. */
  case LBFGSERR_OUTOFINTERVAL: 
    return "LBFGSERR_OUTOFINTERVAL";
  /** A logic error occurred; alternatively, the interval of uncertainty
      became too small. */
  case LBFGSERR_INCORRECT_TMINMAX: 
    return "LBFGSERR_INCORRECT_TMINMAX";
  /** A rounding error occurred; alternatively, no line-search step
      satisfies the sufficient decrease and curvature conditions. */
  case LBFGSERR_ROUNDING_ERROR: 
    return "LBFGSERR_ROUNDING_ERROR";
  /** The line-search step became smaller than LBFGSParameters::min_step. */
  case LBFGSERR_MINIMUMSTEP: 
    return "LBFGSERR_MINIMUMSTEP";
  /** The line-search step became larger than LBFGSParameters::max_step. */
  case LBFGSERR_MAXIMUMSTEP: 
    return "LBFGSERR_MAXIMUMSTEP";
  /** The line-search routine reaches the maximum number of evaluations. */
  case LBFGSERR_MAXIMUMLINESEARCH: 
    return "LBFGSERR_MAXIMUMLINESEARCH";
  /** The algorithm routine reaches the maximum number of iterations. */
  case LBFGSERR_MAXIMUMITERATION: 
    return "LBFGSERR_MAXIMUMITERATION";
  /** Relative width of the interval of uncertainty is at most
      LBFGSParameters::xtol. */
  case LBFGSERR_WIDTHTOOSMALL: 
    return "LBFGSERR_WIDTHTOOSMALL";
  /** A logic error (negative line-search step) occurred. */
  case LBFGSERR_INVALIDPARAMETERS: 
    return "LBFGSERR_INVALIDPARAMETERS";
  /** The current search direction increases the objective function value. */
  case LBFGSERR_INCREASEGRADIENT: 
    return "LBFGSERR_INCREASEGRADIENT";    
  }

  return "UNKNOWN_CODE";
}

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
   *    - f(x + a * d) <= f(x) + LBFGSParameters::ftol * a * g(x)^T d,
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
   *    - g(x + a * d)^T d >= LBFGSParameters::wolfe * g(x)^T d,
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
   *    - |g(x + a * d)^T d| <= LBFGSParameters::wolfe * |g(x)^T d|,
   *
   *  where x is the current point, d is the current search direction, and
   *  a is the step length.
   */
  LBFGS_LINESEARCH_BACKTRACKING_STRONG_WOLFE = 3,
};


#include "lbfgs_utils.mqh"
#include "lbfgs/UserData.mqh"
#include "lbfgs/Parameters.mqh"
#include "lbfgs/ProgressHandler.mqh"
#include "lbfgs/EvaluationHandler.mqh"

struct callback_data_t
{
  int n;
  LBFGSUserData *instance;
  LBFGSEvaluationHandler *proc_evaluate;
  LBFGSProgressHandler *proc_progress;
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
  double &ptr_fx,
  LBFGSEvaluationHandler *proc_evaluate,
  LBFGSProgressHandler *proc_progress,
  LBFGSUserData *instance = NULL,
  LBFGSParameters *_param = NULL
)
{
  int ret = LBFGS_SUCCESS;
  int i, j, k, ls, end, bound;
  double step;

  /* Constant parameters and their default values. */
  LBFGSParameters defaultParams;
  LBFGSParameters *param = _param != NULL ? _param : GetPointer(defaultParams);
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
  CHECK_RET(ArrayResize(xp, n) == n,ret, "Cannot allocate vector");
  CHECK_RET(ArrayResize(g, n) == n,ret, "Cannot allocate vector");
  CHECK_RET(ArrayResize(gp, n) == n,ret, "Cannot allocate vector");
  CHECK_RET(ArrayResize(d, n) == n,ret, "Cannot allocate vector");
  CHECK_RET(ArrayResize(w, n) == n,ret, "Cannot allocate vector");

  if (param.orthantwise_c != 0.)
  {
    /* Allocate working space for OW-LQN. */
    CHECK_RET(ArrayResize(pg, n) == n,ret, "Cannot allocate vector");
  }

  /* Allocate limited memory storage. */
  CHECK_RET(ArrayResize(lm, m) == m,ret, "Cannot allocate lm array.");

  /* Initialize the limited memory. */
  for (i = 0; i < m; ++i)
  {
    lm[i].alpha = 0;
    lm[i].ys = 0;
    CHECK_RET(ArrayResize(lm[i].s, n) == n,ret, "Cannot allocate vector");
    CHECK_RET(ArrayResize(lm[i].y, n) == n,ret, "Cannot allocate vector");
  }

  /* Allocate an array for storing previous values of the objective function. */
  if (0 < param.past)
  {
    CHECK_RET(ArrayResize(pf, param.past) == param.past,ret, "Cannot allocate vector");
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

  ptr_fx = fx;
  return ret;
}
