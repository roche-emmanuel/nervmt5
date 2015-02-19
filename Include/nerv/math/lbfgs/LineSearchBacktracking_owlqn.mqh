#include "LineSearch.mqh"

class LineSearchBacktracking_owlqn : public LBFGSLineSearch
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
    const LBFGSParameters *param)
  {
    int i, count = 0;
    double width = 0.5, norm = 0.;
    double finit = f, dgtest;

    /* Check the input parameters for errors. */
    if (stp <= 0.)
    {
      return LBFGSERR_INVALIDPARAMETERS;
    }

    /* Choose the orthant for the new point. */
    for (i = 0; i < n; ++i)
    {
      wp[i] = (xp[i] == 0.) ? -gp[i] : xp[i];
    }

    for (;;)
    {
      /* Update the current point. */
      veccpy(x, xp, n);
      vecadd(x, s, stp, n);

      /* The current point is projected onto the orthant. */
      owlqn_project(x, wp, param.orthantwise_start, param.orthantwise_end);

      /* Evaluate the function and gradient values. */
      f = cd.proc_evaluate.evaluate(cd.instance, x, g, cd.n, stp);

      /* Compute the L1 norm of the variables and add it to the object value. */
      norm = owlqn_x1norm(x, param.orthantwise_start, param.orthantwise_end);
      f += norm * param.orthantwise_c;

      ++count;

      dgtest = 0.;
      for (i = 0; i < n; ++i)
      {
        dgtest += (x[i] - xp[i]) * gp[i];
      }

      if (f <= finit + param.ftol * dgtest)
      {
        /* The sufficient decrease condition. */
        return count;
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

      stp *= width;
    }

    // Will never be reached.
    return 0;
  }
};

