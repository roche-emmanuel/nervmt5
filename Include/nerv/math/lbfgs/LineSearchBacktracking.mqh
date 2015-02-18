#include "LineSearch.mqh"

class LineSearchBacktracking : public LBFGSLineSearch
{
public:
  virtual int process(
    int n,
    double &x[],
    double &f,
    double &g[],
    double &s[],
    double &stp,
    const double &xp[],
    const double &gp[],
    double &wp[],
    callback_data_t &cd,
    const LBGFSParameters *param)
  {
    int count = 0;
    double width, dg;
    double finit, dginit = 0., dgtest;
    const double dec = 0.5, inc = 2.1;

    /* Check the input parameters for errors. */
    if (stp <= 0.)
    {
      return LBFGSERR_INVALIDPARAMETERS;
    }

    /* Compute the initial gradient in the search direction. */
    dginit = vecdot(g, s, n);

    /* Make sure that s points to a descent direction. */
    if (0 < dginit)
    {
      return LBFGSERR_INCREASEGRADIENT;
    }

    /* The initial value of the objective function. */
    finit = f;
    dgtest = param.ftol * dginit;

    for (;;)
    {
      veccpy(x, xp, n);
      vecadd(x, s, stp, n);

      /* Evaluate the function and gradient values. */
      f = cd.proc_evaluate.evaluate(cd.instance, x, g, cd.n, stp);

      ++count;

      if (f > finit + stp * dgtest)
      {
        width = dec;
      }
      else
      {
        /* The sufficient decrease condition (Armijo condition). */
        if (param.linesearch == LBFGS_LINESEARCH_BACKTRACKING_ARMIJO)
        {
          /* Exit with the Armijo condition. */
          return count;
        }

        /* Check the Wolfe condition. */
        dg = vecdot(g, s, n);
        if (dg < param.wolfe * dginit)
        {
          width = inc;
        }
        else
        {
          if (param.linesearch == LBFGS_LINESEARCH_BACKTRACKING_WOLFE)
          {
            /* Exit with the regular Wolfe condition. */
            return count;
          }

          /* Check the strong Wolfe condition. */
          if (dg > -param.wolfe * dginit)
          {
            width = dec;
          }
          else
          {
            /* Exit with the strong Wolfe condition. */
            return count;
          }
        }
      }


      if (stp < param.min_step)
      {
        /* The step is the minimum value. */
        return LBFGSERR_MINIMUMSTEP;
      }
      if (stp > param.max_step)
      {
        /* The step is the maximum value. */
        return LBFGSERR_MAXIMUMSTEP;
      }
      if (param.max_linesearch <= count)
      {
        /* Maximum number of iteration. */
        return LBFGSERR_MAXIMUMLINESEARCH;
      }

      (stp) *= width;
    }

		// Will never be reached.
    return 0;
  }
};

