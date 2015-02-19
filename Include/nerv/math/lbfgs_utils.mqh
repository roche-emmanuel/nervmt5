
#define fsigndiff(x, y) (x * (y / fabs(y)) < 0.0 ? 1 : 0)
#define SET_OPTIONAL(arr,val) if(ArraySize(arr)>0) { arr[0] = val; }

#define min2(a, b)      ((a) <= (b) ? (a) : (b))
#define max2(a, b)      ((a) >= (b) ? (a) : (b))
#define max3(a, b, c)   max2(max2((a), (b)), (c));

#define LBFGS_EXIT(code) { ptr_fx = fx; return code; }


/**
 * Define the local variables for computing minimizers.
 */
#define USES_MINIMIZER \
  double a, d, gamma, theta, p, q, r, s;

/**
 * Find a minimizer of an interpolated cubic function.
 *  @param  cm      The minimizer of the interpolated cubic.
 *  @param  u       The value of one point, u.
 *  @param  fu      The value of f(u).
 *  @param  du      The value of f'(u).
 *  @param  v       The value of another point, v.
 *  @param  fv      The value of f(v).
 *  @param  du      The value of f'(v).
 */
#define CUBIC_MINIMIZER(cm, u, fu, du, v, fv, dv) \
  d = (v) - (u); \
  theta = ((fu) - (fv)) * 3 / d + (du) + (dv); \
  p = fabs(theta); \
  q = fabs(du); \
  r = fabs(dv); \
  s = max3(p, q, r); \
  /* gamma = s*sqrt((theta/s)**2 - (du/s) * (dv/s)) */ \
  a = theta / s; \
  gamma = s * sqrt(a * a - ((du) / s) * ((dv) / s)); \
  if ((v) < (u)) gamma = -gamma; \
  p = gamma - (du) + theta; \
  q = gamma - (du) + gamma + (dv); \
  r = p / q; \
  (cm) = (u) + r * d;

/**
 * Find a minimizer of an interpolated cubic function.
 *  @param  cm      The minimizer of the interpolated cubic.
 *  @param  u       The value of one point, u.
 *  @param  fu      The value of f(u).
 *  @param  du      The value of f'(u).
 *  @param  v       The value of another point, v.
 *  @param  fv      The value of f(v).
 *  @param  du      The value of f'(v).
 *  @param  xmin    The maximum value.
 *  @param  xmin    The minimum value.
 */
#define CUBIC_MINIMIZER2(cm, u, fu, du, v, fv, dv) \
  d = (v) - (u); \
  theta = ((fu) - (fv)) * 3 / d + (du) + (dv); \
  p = fabs(theta); \
  q = fabs(du); \
  r = fabs(dv); \
  s = max3(p, q, r); \
  /* gamma = s*sqrt((theta/s)**2 - (du/s) * (dv/s)) */ \
  a = theta / s; \
  gamma = s * sqrt(max2(0, a * a - ((du) / s) * ((dv) / s))); \
  if ((u) < (v)) gamma = -gamma; \
  p = gamma - (dv) + theta; \
  q = gamma - (dv) + gamma + (du); \
  r = p / q; \
  if (r < 0. && gamma != 0.) { \
    (cm) = (v) - r * d; \
  } else if (a < 0) { \
    (cm) = (tmax); \
  } else { \
    (cm) = (tmin); \
  }

/**
 * Find a minimizer of an interpolated quadratic function.
 *  @param  qm      The minimizer of the interpolated quadratic.
 *  @param  u       The value of one point, u.
 *  @param  fu      The value of f(u).
 *  @param  du      The value of f'(u).
 *  @param  v       The value of another point, v.
 *  @param  fv      The value of f(v).
 */
#define QUARD_MINIMIZER(qm, u, fu, du, v, fv) \
  a = (v) - (u); \
  (qm) = (u) + (du) / (((fu) - (fv)) / a + (du)) / 2 * a;

/**
 * Find a minimizer of an interpolated quadratic function.
 *  @param  qm      The minimizer of the interpolated quadratic.
 *  @param  u       The value of one point, u.
 *  @param  du      The value of f'(u).
 *  @param  v       The value of another point, v.
 *  @param  dv      The value of f'(v).
 */
#define QUARD_MINIMIZER2(qm, u, du, v, dv) \
  a = (u) - (v); \
  (qm) = (v) + (dv) / ((dv) - (du)) * a;


void vecset(double &x[], const double c, const int n)
{
  int i;

  for (i = 0; i < n; ++i)
  {
    x[i] = c;
  }
}

void veccpy(double &y[], const double &x[], const int n)
{
  int i;

  for (i = 0; i < n; ++i)
  {
    y[i] = x[i];
  }
}

void vecncpy(double &y[], const double &x[], const int n)
{
  int i;

  for (i = 0; i < n; ++i)
  {
    y[i] = -x[i];
  }
}

void vecadd(double &y[], const double &x[], const double c, const int n)
{
  int i;

  for (i = 0; i < n; ++i)
  {
    y[i] += c * x[i];
  }
}

void vecdiff(double &z[], const double &x[], const double &y[], const int n)
{
  int i;

  for (i = 0; i < n; ++i)
  {
    z[i] = x[i] - y[i];
  }
}

void vecscale(double &y[], const double c, const int n)
{
  int i;

  for (i = 0; i < n; ++i)
  {
    y[i] *= c;
  }
}

void vecmul(double &y[], const double &x[], const int n)
{
  int i;

  for (i = 0; i < n; ++i)
  {
    y[i] *= x[i];
  }
}

double vecdot(const double &x[], const double &y[], const int n)
{
  int i;
  double s = 0.;
  for (i = 0; i < n; ++i)
  {
    s += x[i] * y[i];
  }
  return s;
}

double vec2norm(const double &x[], const int n)
{
  double s = vecdot(x, x, n);
  return MathSqrt(s);
}

double vec2norminv(const double &x[], const int n)
{
  double s = vec2norm(x, n);
  return (1.0 / s);
}

double owlqn_x1norm(
  const double &x[],
  const int start,
  const int n
)
{
  int i;
  double norm = 0.;

  for (i = start; i < n; ++i)
  {
    norm += fabs(x[i]);
  }

  return norm;
}

void owlqn_pseudo_gradient(
  double &pg[],
  const double &x[],
  const double &g[],
  const int n,
  const double c,
  const int start,
  const int end
)
{
  int i;

  /* Compute the negative of gradients. */
  for (i = 0; i < start; ++i)
  {
    pg[i] = g[i];
  }

  /* Compute the psuedo-gradients. */
  for (i = start; i < end; ++i)
  {
    if (x[i] < 0.)
    {
      /* Differentiable. */
      pg[i] = g[i] - c;
    }
    else if (0. < x[i])
    {
      /* Differentiable. */
      pg[i] = g[i] + c;
    }
    else
    {
      if (g[i] < -c)
      {
        /* Take the right partial derivative. */
        pg[i] = g[i] + c;
      }
      else if (c < g[i])
      {
        /* Take the left partial derivative. */
        pg[i] = g[i] - c;
      }
      else
      {
        pg[i] = 0.;
      }
    }
  }

  for (i = end; i < n; ++i)
  {
    pg[i] = g[i];
  }
}

void owlqn_project(
  double &d[],
  const double &sign[],
  const int start,
  const int end
)
{
  int i;

  for (i = start; i < end; ++i)
  {
    if (d[i] * sign[i] <= 0)
    {
      d[i] = 0;
    }
  }
}

/**
 * Update a safeguarded trial value and interval for line search.
 *
 *  The parameter x represents the step with the least function value.
 *  The parameter t represents the current step. This function assumes
 *  that the derivative at the point of x in the direction of the step.
 *  If the bracket is set to true, the minimizer has been bracketed in
 *  an interval of uncertainty with endpoints between x and y.
 *
 *  @param  x       The pointer to the value of one endpoint.
 *  @param  fx      The pointer to the value of f(x).
 *  @param  dx      The pointer to the value of f'(x).
 *  @param  y       The pointer to the value of another endpoint.
 *  @param  fy      The pointer to the value of f(y).
 *  @param  dy      The pointer to the value of f'(y).
 *  @param  t       The pointer to the value of the trial value, t.
 *  @param  ft      The pointer to the value of f(t).
 *  @param  dt      The pointer to the value of f'(t).
 *  @param  tmin    The minimum value for the trial value, t.
 *  @param  tmax    The maximum value for the trial value, t.
 *  @param  brackt  The pointer to the predicate if the trial value is
 *                  bracketed.
 *  @retval int     Status value. Zero indicates a normal termination.
 *
 *  @see
 *      Jorge J. More and David J. Thuente. Line search algorithm with
 *      guaranteed sufficient decrease. ACM Transactions on Mathematical
 *      Software (TOMS), Vol 20, No 3, pp. 286-307, 1994.
 */
int update_trial_interval(
  double &x,
  double &fx,
  double &dx,
  double &y,
  double &fy,
  double &dy,
  double &t,
  double &ft,
  double &dt,
  const double tmin,
  const double tmax,
  int &brackt
)
{
  int bound;
  int dsign = fsigndiff(dt, dx);
  double mc; /* minimizer of an interpolated cubic. */
  double mq; /* minimizer of an interpolated quadratic. */
  double newt;   /* new trial value. */
  USES_MINIMIZER;     /* for CUBIC_MINIMIZER and QUARD_MINIMIZER. */

  /* Check the input parameters for errors. */
  if (brackt)
  {
    if (t <= min2(x, y) || max2(x, y) <= t)
    {
      /* The trival value t is out of the interval. */
      return LBFGSERR_OUTOFINTERVAL;
    }
    if (0. <= dx * (t - x))
    {
      /* The function must decrease from x. */
      return LBFGSERR_INCREASEGRADIENT;
    }
    if (tmax < tmin)
    {
      /* Incorrect tmin and tmax specified. */
      return LBFGSERR_INCORRECT_TMINMAX;
    }
  }



  /*
      Trial value selection.
   */
  if (fx < ft)
  {
    /*
        Case 1: a higher function value.
        The minimum is brackt. If the cubic minimizer is closer
        to x than the quadratic one, the cubic one is taken, else
        the average of the minimizers is taken.
     */
    brackt = 1;
    bound = 1;
    CUBIC_MINIMIZER(mc, x, fx, dx, t, ft, dt);
    QUARD_MINIMIZER(mq, x, fx, dx, t, ft);
    if (fabs(mc - x) < fabs(mq - x))
    {
      newt = mc;
    }
    else
    {
      newt = mc + 0.5 * (mq - mc);
    }
  }
  else if (dsign)
  {
    /*
        Case 2: a lower function value and derivatives of
        opposite sign. The minimum is brackt. If the cubic
        minimizer is closer to x than the quadratic (secant) one,
        the cubic one is taken, else the quadratic one is taken.
     */
    brackt = 1;
    bound = 0;
    CUBIC_MINIMIZER(mc, x, fx, dx, t, ft, dt);
    QUARD_MINIMIZER2(mq, x, dx, t, dt);
    if (fabs(mc - t) > fabs(mq - t))
    {
      newt = mc;
    }
    else
    {
      newt = mq;
    }
  }
  else if (fabs(dt) < fabs(dx))
  {
    /*
        Case 3: a lower function value, derivatives of the
        same sign, and the magnitude of the derivative decreases.
        The cubic minimizer is only used if the cubic tends to
        infinity in the direction of the minimizer or if the minimum
        of the cubic is beyond t. Otherwise the cubic minimizer is
        defined to be either tmin or tmax. The quadratic (secant)
        minimizer is also computed and if the minimum is brackt
        then the the minimizer closest to x is taken, else the one
        farthest away is taken.
     */
    bound = 1;
    CUBIC_MINIMIZER2(mc, x, fx, dx, t, ft, dt);
    QUARD_MINIMIZER2(mq, x, dx, t, dt);
    if (brackt)
    {
      if (fabs(t - mc) < fabs(t - mq))
      {
        newt = mc;
      }
      else
      {
        newt = mq;
      }
    }
    else
    {
      if (fabs(t - mc) > fabs(t - mq))
      {
        newt = mc;
      }
      else
      {
        newt = mq;
      }
    }
  }
  else
  {
    /*
        Case 4: a lower function value, derivatives of the
        same sign, and the magnitude of the derivative does
        not decrease. If the minimum is not brackt, the step
        is either tmin or tmax, else the cubic minimizer is taken.
     */
    bound = 0;
    if (brackt)
    {
      CUBIC_MINIMIZER(newt, t, ft, dt, y, fy, dy);
    }
    else if (x < t)
    {
      newt = tmax;
    }
    else
    {
      newt = tmin;
    }
  }

  /*
      Update the interval of uncertainty. This update does not
      depend on the new step or the case analysis above.

      - Case a: if f(x) < f(t),
          x <- x, y <- t.
      - Case b: if f(t) <= f(x) && f'(t)*f'(x) > 0,
          x <- t, y <- y.
      - Case c: if f(t) <= f(x) && f'(t)*f'(x) < 0,
          x <- t, y <- x.
   */
  if (fx < ft)
  {
    /* Case a */
    y = t;
    fy = ft;
    dy = dt;
  }
  else
  {
    /* Case c */
    if (dsign)
    {
      y = x;
      fy = fx;
      dy = dx;
    }
    /* Cases b and c */
    x = t;
    fx = ft;
    dx = dt;
  }

  /* Clip the new trial value in [tmin, tmax]. */
  if (tmax < newt) newt = tmax;
  if (newt < tmin) newt = tmin;


  /*
      Redefine the new trial value if it is close to the upper bound
      of the interval.
   */
  if (brackt && bound)
  {
    mq = x + 0.66 * (y - x);
    if (x < y)
    {
      if (mq < newt) newt = mq;
    }
    else
    {
      if (newt < mq) newt = mq;
    }
  }

  /* Return the new trial value. */
  t = newt;
  return 0;
}
