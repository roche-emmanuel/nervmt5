
// fminlbfgs implementation derived from octave version.

struct fminResult
{
  double x[];
  double fval;
  double grad[];
};

class fminData
{
public:
  //double fval=0;
  //double gradient=0;
  //double fOld=[]; 
  //double xsizes=size(x_init);
  //double numberOfVariables = numel(x_init);
  //double xInitial = x_init(:);
  //double alpha=1;
  //double xOld= //double xInitial; 
  //double iteration=0;
  //double funcCount=0;
  //double gradCount=0;
  //double exitflag=[];
  //double nStored=0;  

  fminData() {
    //fval = 0.0;
    //gradient = 0.0;
  }
};

class fminFunction
{
public:
  virtual double eval(double &x[]) // might need to specify with gradient ?
  {
    return 0.0;
  }
};

class fminParams
{
public:
  /* Number of itterations used to approximate the Hessian,
   in L-BFGS, 20 is default. A lower value may work better with
   non smooth functions, because than the Hessian is only valid for
   a specific position. A higher value is recommend with quadratic equations. */
  int storeN;

  /* Termination tolerance on x, default 1e-6. */
  double tolX;

  /* Termination tolerance on the function value, default 1e-6 */
  double tolFun;

  /* Maximum number of iterations allowed, default 400 */
  int maxIter;

  /* Maximum number of function evaluations allowed,
     default 100 times the amount of unknowns. */
  int maxFunEvals;

  /* Wolfe condition on gradient (c1 on wikipedia), default 0.01.*/
  double rho;

  /* Wolfe condition on gradient (c2 on wikipedia), default 0.9.*/
  double sigma;

  /* Bracket expansion if stepsize becomes larger, default 3.*/
  double tau1;

  /* Left bracket reduction used in section phase, default 0.1.*/
  double tau2;

  /* Right bracket reduction used in section phase, default 0.5*/
  double tau3;

  /*Set this variable to true if gradient calls are
    cpu-expensive (default). If false more gradient calls are
    used and less function calls. */
  int gradConstr;

  /* Maximum stepsize used for finite difference gradients. */
  double diffMaxChange;

  /* Minimum stepsize used for finite difference gradients. */
  double diffMinChange;

  fminParams() : storeN(20), tolX(1e-6), tolFun(1e-6),
    maxIter(400), maxFunEvals(1000), rho(0.01), sigma(0.9),
    tau1(3.0), tau2(0.1), tau3(0.5), gradConstr(1),
    diffMaxChange(1e-1), diffMinChange(1e-8)
  {};
};

// exit codes:
enum
{
  /* Number of iterations exceeded options.MaxIter or number of
  function evaluations exceeded options.FunEvals. */
  FMIN_REACHED_MAXITER = 0,
  /* Change in the objective function value was less than the
  specified tolerance TolFun.*/
  FMIN_REACHED_TOLFUN,
  /* Change in x was smaller than the specified tolerance TolX.*/
  FMIN_REACHED_TOLX,
  /* Magnitude of gradient smaller than the specified tolerance */
  FMIN_REACHED_TOLGRAD,
  /* Boundary fminimum reached. */
  FMIN_REACHED_BOUNDARY,
  /* Line search cannot find an acceptable point along the current search */
  FMIN_INVALID_LINESEARCH_POINT = -1
};

/*
fminlbfgs finds a local minimum of a function of several variables.

Optimization methods supported:
- Quasi Newton Broyden–Fletcher–Goldfarb–Shanno (BFGS)

Inputs:
  results : structure containing the result data.
  x_init : initial values for the x variables.
  func: the cost function to evaluate.
  params: the parameters to use.
*/
int fminlbfgs(fminResult &results, double &x_init[], fminFunction *func, fminParams *paramsIn = NULL)
{

  fminParams defParams;

  fminParams* params = paramsIn!=NULL ? paramsIn : GetPointer(defParams);

  
  return 0;
}