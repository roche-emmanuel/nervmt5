#include "LineSearch.mqh"

class LineSearchMorethuente : public LBFGSLineSearch
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
    int brackt, stage1, uinfo = 0;
    double dg;
    double stx, fx, dgx;
    double sty, fy, dgy;
    double fxm, dgxm, fym, dgym, fm, dgm;
    double finit, ftest1, dginit, dgtest;
    double width, prev_width;
    double stmin, stmax;

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

    /* Initialize local variables. */
    brackt = 0;
    stage1 = 1;
    finit = f;
    dgtest = param.ftol * dginit;
    width = param.max_step - param.min_step;
    prev_width = 2.0 * width;

    /*
        The variables stx, fx, dgx contain the values of the step,
        function, and directional derivative at the best step.
        The variables sty, fy, dgy contain the value of the step,
        function, and derivative at the other endpoint of
        the interval of uncertainty.
        The variables stp, f, dg contain the values of the step,
        function, and derivative at the current step.
    */
    stx = sty = 0.;
    fx = fy = finit;
    dgx = dgy = dginit;

    for (;;)
    {
      /*
       Set the minimum and maximum steps to correspond to the
       present interval of uncertainty.
      */
      if (brackt)
      {
        stmin = min2(stx, sty);
        stmax = max2(stx, sty);
      }
      else
      {
        stmin = stx;
        stmax = stp + 4.0 * (stp - stx);
      }

      /* Clip the step in the range of [stpmin, stpmax]. */
      if (stp < param.min_step) stp = param.min_step;
      if (param.max_step < stp) stp = param.max_step;

      /*
          If an unusual termination is to occur then let
          stp be the lowest point obtained so far.
       */
      if ((brackt && ((stp <= stmin || stmax <= stp) || param.max_linesearch <= count + 1 || uinfo != 0)) || (brackt && (stmax - stmin <= param.xtol * stmax)))
      {
        stp = stx;
      }

      /*
          Compute the current value of x:
              x <- x + (*stp) * s.
       */
      veccpy(x, xp, n);
      vecadd(x, s, stp, n);

      /* Evaluate the function and gradient values. */
      f = cd.proc_evaluate.evaluate(cd.instance, x, g, cd.n, stp);
      dg = vecdot(g, s, n);

      ftest1 = finit + stp * dgtest;
      ++count;

      /* Test for errors and convergence. */
      if (brackt && ((stp <= stmin || stmax <= stp) || uinfo != 0))
      {
        /* Rounding errors prevent further progress. */
        return LBFGSERR_ROUNDING_ERROR;
      }
      if (stp == param.max_step && f <= ftest1 && dg <= dgtest)
      {
        /* The step is the maximum value. */
        return LBFGSERR_MAXIMUMSTEP;
      }
      if (stp == param.min_step && (ftest1 < f || dgtest <= dg))
      {
        /* The step is the minimum value. */
        return LBFGSERR_MINIMUMSTEP;
      }
      if (brackt && (stmax - stmin) <= param.xtol * stmax)
      {
        /* Relative width of the interval of uncertainty is at most xtol. */
        return LBFGSERR_WIDTHTOOSMALL;
      }
      if (param.max_linesearch <= count)
      {
        /* Maximum number of iteration. */
        return LBFGSERR_MAXIMUMLINESEARCH;
      }
      if (f <= ftest1 && fabs(dg) <= param.gtol * (-dginit))
      {
        /* The sufficient decrease condition and the directional derivative condition hold. */
        return count;
      }

      /*
          In the first stage we seek a step for which the modified
          function has a nonpositive value and nonnegative derivative.
       */
      if (stage1 && f <= ftest1 && min2(param.ftol, param.gtol) * dginit <= dg)
      {
        stage1 = 0;
      }

      /*
          A modified function is used to predict the step only if
          we have not obtained a step for which the modified
          function has a nonpositive function value and nonnegative
          derivative, and if a lower function value has been
          obtained but the decrease is not sufficient.
       */
      if (stage1 && ftest1 < f && f <= fx)
      {
        /* Define the modified function and derivative values. */
        fm = f - stp * dgtest;
        fxm = fx - stx * dgtest;
        fym = fy - sty * dgtest;
        dgm = dg - dgtest;
        dgxm = dgx - dgtest;
        dgym = dgy - dgtest;

        /*
            Call update_trial_interval() to update the interval of
            uncertainty and to compute the new step.
         */
        uinfo = update_trial_interval(
                  stx, fxm, dgxm,
                  sty, fym, dgym,
                  stp, fm, dgm,
                  stmin, stmax, brackt
                );

        /* Reset the function and gradient values for f. */
        fx = fxm + stx * dgtest;
        fy = fym + sty * dgtest;
        dgx = dgxm + dgtest;
        dgy = dgym + dgtest;
      }
      else
      {
        /*
            Call update_trial_interval() to update the interval of
            uncertainty and to compute the new step.
         */
        uinfo = update_trial_interval(
                  stx, fx, dgx,
                  sty, fy, dgy,
                  stp, f, dg,
                  stmin, stmax, brackt
                );
      }


      /*
         Force a sufficient decrease in the interval of uncertainty.
      */
      if (brackt)
      {
        if (0.66 * prev_width <= fabs(sty - stx))
        {
          stp = stx + 0.5 * (sty - stx);
        }
        prev_width = width;
        width = fabs(sty - stx);
      }
    }

    return LBFGSERR_LOGICERROR;
  }
};

