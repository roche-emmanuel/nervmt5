
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trades.mqh>
#include <nerv/math.mqh>

BEGIN_TEST_PACKAGE(rrlmodel_specs)

BEGIN_TEST_SUITE("RRLModel class")

BEGIN_TEST_CASE("should be able to create an RRL model")
  nvRRLModel* model = new nvRRLModel(10);  
  REQUIRE(model!=NULL);
  delete model;
END_TEST_CASE()

XBEGIN_TEST_CASE("should be able to train on some data")
  int ni = 10;
  string symbol = "EURUSD";
  ENUM_TIMEFRAMES period = PERIOD_M1;

  nvRRLModel model(ni);  

  // Retrieve the data we need:
  int ns = 1000+ni-1;

  // Initialize the price return vector:
  nvVecd returns = nv_get_return_prices(ns,symbol,period);

  REQUIRE_EQUAL(returns.size(),ns);
  nvVecd nrets = returns.stdnormalize();
  
  double sr = model.train_batch(GetPointer(nrets),GetPointer(returns),0.0008);
  DISPLAY(sr);
  REQUIRE(MathAbs(sr)<1.0);
END_TEST_CASE()

BEGIN_TEST_CASE("should provide the same results on the DAX template")
  int M = 10;
  int T = 500;
  //nvRRLModel model(M);
  nvVecd returns = nv_read_vecd("retDAX.txt");

  nvVecd nrets = returns.stdnormalize();

  returns = returns.subvec(0,M+T);
  nrets = nrets.subvec(0,M+T);

  //DISPLAY(returns.subvec(0,10));
  //DISPLAY(nrets.subvec(0,10));

  REQUIRE_EQUAL(returns.size(),M+T);

	nvVecd theta(12,1.0);
  nvVecd grad(12);
  double delta = 0.001;

  double cost = rrlCostFunction(GetPointer(nrets),GetPointer(returns),delta,GetPointer(grad),GetPointer(theta));

  DISPLAY(cost);
  DISPLAY(grad);  
END_TEST_CASE()


BEGIN_TEST_CASE("should not fall in pathological case")
  int M = 10;
  int T = 500;
  //nvRRLModel model(M);
  nvVecd returns = nv_read_vecd("retDAX.txt");

  nvVecd nrets = returns.stdnormalize();

  returns = returns.subvec(0,M+T);
  nrets = nrets.subvec(0,M+T);

  //DISPLAY(returns.subvec(0,10));
  //DISPLAY(nrets.subvec(0,10));

  REQUIRE_EQUAL(returns.size(),M+T);

  double arr[] = {-8.211269623521567,76.49361421859899,36.24277374304108,40.5393781918585,-0.2008760575959007,14.7561347862186,28.94807910223942,9.912719339652838,32.21584258735472,30.15722544464128,3.093312069285194,92.44428041635105};

  nvVecd theta(arr);
  nvVecd grad(12);
  double delta = 0.001;

  double cost = rrlCostFunction(GetPointer(nrets),GetPointer(returns),delta,GetPointer(grad),GetPointer(theta));

  DISPLAY(cost);
  DISPLAY(grad);  
END_TEST_CASE()

BEGIN_TEST_CASE("should find proper optimum")
  int M = 10;
  int T = 500;
  //nvRRLModel model(M);
  nvVecd returns = nv_read_vecd("retDAX.txt");

  nvVecd nrets = returns.stdnormalize();

  returns = returns.subvec(0,M+T);
  nrets = nrets.subvec(0,M+T);

  //DISPLAY(returns.subvec(0,10));
  //DISPLAY(nrets.subvec(0,10));

  REQUIRE_EQUAL(returns.size(),M+T);

  double arr[] = {   
   -401.9593360970943,
   1242.3870115722934,
    -74.8562671676811,
    657.7968112264138,
    -41.9980560569779,
   -150.4420847696033,
   -185.3185924803570,
     44.0739632019500,
     15.1930525093485,
    568.4555479305243,
   -587.5584364155962,
    438.4129658534276
  };

  nvVecd theta(arr);
  nvVecd grad(12);
  double delta = 0.001;

  double cost = rrlCostFunction(GetPointer(nrets),GetPointer(returns),delta,GetPointer(grad),GetPointer(theta));

  DISPLAY(cost);
  DISPLAY(grad);  
END_TEST_CASE()


BEGIN_TEST_CASE("should be able to train on DAX template")
  //nvRRLModel model(M);

  class Evaluator : public LBFGSEvaluationHandler
  {
  protected:
    nvVecd _returns;
    nvVecd _nrets;
    nvVecd _grad;
    nvVecd _theta;
		double _delta;
		
  public:
    Evaluator() {
      int M = 10;
      int T = 500;

      nvVecd returns = nv_read_vecd("retDAX.txt");

      nvVecd nrets = returns.stdnormalize();

      _returns = returns.subvec(0,M+T);
      _nrets = nrets.subvec(0,M+T);  

      _delta = 0.001;
    }

    virtual double evaluate(LBFGSUserData *instance, const double &x[], double &grad[], int n, double step)
    {
      _theta = x;
      //logDEBUG("Theta: "<<_theta);
      double cost = rrlCostFunction(GetPointer(_nrets),GetPointer(_returns),_delta,GetPointer(_grad),GetPointer(_theta));
      //logDEBUG("Computed cost: "<<cost);

      _grad.toArray(grad);
      return cost;
    };   
  };

  double x[];
  double fx = 0.0;
  nvVecd init_theta(12,1.0);
  init_theta.toArray(x);

  Evaluator ev;
  LBFGSDefaultProgressHandler prog;
  LBFGSParameters params;
  params.m = 20;
  params.epsilon = 1e-6;
  params.ftol = 0.0001;
  params.gtol = 0.9;
  //params.linesearch = LBFGS_LINESEARCH_BACKTRACKING;
  params.linesearch = LBFGS_LINESEARCH_BACKTRACKING_WOLFE;
  //params.linesearch = LBFGS_LINESEARCH_BACKTRACKING_STRONG_WOLFE;
  params.max_linesearch = 40;

  int ret = lbfgs(12,x,fx,GetPointer(ev),GetPointer(prog),NULL,GetPointer(params));
  logDEBUG("Got error code: "<<lbfgs_code_string(ret));

  REQUIRE_EQUAL(ret,0);
  DISPLAY(fx);

  //double cost = model.costFunction(GetPointer(nrets),GetPointer(returns),delta,GetPointer(grad));
  //nvVecd ratios;
  //int nepochs = 30;
  //model.train(GetPointer(returns),delta,nepochs,GetPointer(nrets),GetPointer(ratios));

  //DISPLAY(ratios[0]);
  //DISPLAY(ratios[nepochs-1]);
END_TEST_CASE()

XBEGIN_TEST_CASE("should make progress during training")
  int ni = 10;
  string symbol = "EURUSD";
  ENUM_TIMEFRAMES period = PERIOD_M1;
  int num = 30;

  for(int i=0;i<num;++i) {

    nvRRLModel model(ni);  

    int offset = nv_random_int(0,30000);

    //logDEBUG("offset is: "<<offset);

    // Retrieve the data we need:
    int ns = 1000+ni-1;

    // Initialize the price return vector:
    nvVecd returns = nv_get_return_prices(ns,symbol,period);

    nvVecd ratios;
    int nepochs = 30;
    model.train(GetPointer(returns),0.0001,nepochs,GetPointer(ratios));

    DISPLAY(ratios[0]);
    DISPLAY(ratios[nepochs-1]);

    REQUIRE_EQUAL(ratios.size(),nepochs);
    //for(int i=0;i<nepochs-1;++i) 
    //{
    //  REQUIRE_LT(ratios[i],ratios[i+1]);
    //}
    REQUIRE_GT(ratios[nepochs-1], ratios[0]);
  }

END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()
