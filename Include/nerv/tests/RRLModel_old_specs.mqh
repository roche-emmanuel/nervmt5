
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trades.mqh>
#include <nerv/math.mqh>
#include <nerv/trade/RRLStrategyDry.mqh>

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
  
  //double sr = model.train_batch(GetPointer(nrets),GetPointer(returns),0.0008);
  //DISPLAY(sr);
  //REQUIRE(MathAbs(sr)<1.0);
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

  double cost = rrlCostFunction(GetPointer(nrets),GetPointer(returns),delta,0.0, 0.0, GetPointer(grad),GetPointer(theta));

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

  double cost = rrlCostFunction(GetPointer(nrets),GetPointer(returns),delta, 0.0, 0.0, GetPointer(grad),GetPointer(theta));

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

  double cost = rrlCostFunction(GetPointer(nrets),GetPointer(returns),delta,0.0, 0.0, GetPointer(grad),GetPointer(theta));

  DISPLAY(cost);
  DISPLAY(grad);  
END_TEST_CASE()

BEGIN_TEST_CASE("should find proper optimum bis")
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
    -15.23069841524252, 
    43.79554024742816,
     23.74058286573723,
     26.43800706903549,
     -13.85963287631363,
     9.853558791361456,
     -1.236528735546739,
     -12.64167803290192,
     -8.852711611829474,
     13.68361514513847,
     -31.24813597441442,
     35.27031101263912
  };

  nvVecd theta(arr);
  nvVecd grad(12);
  double delta = 0.001;

  double cost = rrlCostFunction(GetPointer(nrets),GetPointer(returns),delta, 0.0, 0.0, GetPointer(grad),GetPointer(theta));

  DISPLAY(cost);
  DISPLAY(grad);  
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to train on DAX template with mincg")
  double x[];
  double fx = 0.0;
  nvVecd init_theta(12,1.0);
  init_theta.toArray(x);

  CMinCGStateShell state;
  CAlglib::MinCGCreate(x,state);

  double epsg = 0.0000000001;
  double epsf = 0;
  double epsx = 0;
  int maxits = 100;

  CAlglib::MinCGSetCond(state, epsg, epsf, epsx, maxits);


  class Evaluator : public CNDimensional_Grad
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

    virtual void Grad(double &x[],double &func,double &grad[],CObject &obj)
    {
      _theta = x;
      //logDEBUG("Theta: "<<_theta);
      func = rrlCostFunction(GetPointer(_nrets),GetPointer(_returns),_delta, 0.0, 0.0, GetPointer(_grad),GetPointer(_theta));
      //logDEBUG("Computed cost: "<<func);
      _grad.toArray(grad);
    };   
  };

  class Report : public CNDimensional_Rep
  {
  public:
    virtual void      Rep(double &arg[],double func,CObject &obj)
    {
      logDEBUG("Reporting cost value: "<<func);
    }
  };

  Evaluator ev;
  Report rep;

  CObject obj;
  logDEBUG("Starting optimization...");
  CAlglib::MinCGOptimize(state,ev,rep,true,obj);
  logDEBUG("Optimization done.");

  CMinCGReportShell res;
  CAlglib::MinCGResults(state, x, res);

  DISPLAY(x);
  
  //ev.Grad(x,fx,grad,obj);
  //DISPLAY(fx);
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to train on DAX template with RRLModel")
  
  int M = 10;
  int T = 500;

  nvVecd returns = nv_read_vecd("retDAX.txt");

  //nvVecd nrets = returns.stdnormalize();

  returns = returns.subvec(0,M+T);
  //nrets = nrets.subvec(0,M+T);  

  double delta = 0.001;

  nvRRLModel model(10);  
	
	nvVecd initx(10,1.0);
  double cost = model.train_cg(delta,0.0,0.0,GetPointer(initx),GetPointer(returns));

  DISPLAY(cost);  
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to train on EURUSD template with RRLModel")
  
  int M = 10;
  int T = 600;

  nvVecd returns = nv_read_vecd("eur_returns.txt");
  REQUIRE_EQUAL(returns.size(),7122);

  //nvVecd nrets = returns.stdnormalize();

  returns = returns.subvec(0,T);
  //nrets = nrets.subvec(0,M+T);  

  double delta = 0.00001;

  nvRRLModel model(M,50);  

	nvVecd initx(12,1.0);
  double cost = model.train_cg(delta,0.0, 0.0, GetPointer(initx),GetPointer(returns));

  double sr = -cost;
  DISPLAY(cost);  

  // Now we try to re-evaluate all the samples, to check how much profit we can get:
  double Ft_1 = 0.0;
  nvVecd rvec(M);
  nvVecd wealth(T);
  nvVecd signal(T);
  nvVecd rets(T-M+1);

  double total = 0.0;

  for(int i=0;i<T;++i)
  {
    double rt = returns[i];
    rvec.push_back(rt);
    if(i<M-1)
    {
      continue;
    }

    // We have enough elements in the vector, so we can start evaluating:
    double Ft;
    model.predict(GetPointer(rvec),Ft_1,Ft);
    //logDEBUG("Predicting: Ft="<<Ft);

    // Compute the Rt value:
    double Rt = Ft_1 *rt - delta * MathAbs(Ft - Ft_1);
    rets.push_back(Rt);

    wealth.set(i,wealth[i-1]+Rt);
    Ft_1 = Ft;
    signal.set(i,Ft);
  }

  // write the wealth:
  nv_write_vecd(GetPointer(wealth),"test_wealth.txt");
  nv_write_vecd(GetPointer(signal),"test_signal.txt");

  // Recompute the observed sharpe ratio:
  double A = rets.mean();
  double B = rets.norm2()/rets.size();
  double osr = A/sqrt(B-A*A);
  
  // This assertion is not met anymore since we now provide the Fstart and Fend values.
  //REQUIRE_EQUAL(sr,osr);
  
END_TEST_CASE()


XBEGIN_TEST_CASE("should be able to train on DAX template")
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
      double cost = rrlCostFunction(GetPointer(_nrets),GetPointer(_returns),_delta, 0.0, 0.0, GetPointer(_grad),GetPointer(_theta));
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
    //model.train(GetPointer(returns),0.0001,nepochs,GetPointer(ratios));

    //DISPLAY(ratios[0]);
    //DISPLAY(ratios[nepochs-1]);

    //REQUIRE_EQUAL(ratios.size(),nepochs);
    //for(int i=0;i<nepochs-1;++i) 
    //{
    //  REQUIRE_LT(ratios[i],ratios[i+1]);
    //}
    //REQUIRE_GT(ratios[nepochs-1], ratios[0]);
  }

END_TEST_CASE()

BEGIN_TEST_CASE("should be able to reproduce the behavior of a dry RRL strategy")

  nvVecd prices = nv_read_vecd("eur_prices.txt");
  REQUIRE_EQUAL(prices.size(),7123);

  double tcost = 0.000001;
  int trainlen = 600;
  int evallen = 100;

  nvRRLStrategyDry strategy(tcost, 10, trainlen, evallen, _Symbol,_Period);
  strategy.setMaxIterations(20);

  nvVecd rets;
  REQUIRE_EQUAL(rets.size(),0);

  strategy.dryrun(GetPointer(prices),GetPointer(rets));
  REQUIRE_EQUAL(rets.size(),prices.size()-1);

  // Build the wealth vector:
  uint num = rets.size();
  nvVecd wealth(num);
  double total = 0.0;
  for(uint i=0;i<num-1;++i) {
    total += rets[i];
    wealth.set(i+1,total);
  }

  // read the template wealth vector:
  nvVecd tw = nv_read_vecd("template_wealth.txt");
  
  //nv_write_vecd(GetPointer(wealth),"result_wealth.txt");  
  
  // Should update the template_wealth file to restore this test.
  // => Since we are now using the Fstart and Fend values.

  //REQUIRE_LT((wealth-tw).norm(),1e-3);
END_TEST_CASE()


XBEGIN_TEST_CASE("should find the best settings for maximizing profits on one week for EURUSD")
  //double x[] = {0.000001,600,100};
  double x[] = {600,100};

  double fx = 0.0;

  CMinCGStateShell state;
  double dstep = 2.0;
  CAlglib::MinCGCreateF(x,dstep,state);
  
  // variable scales:
  //double s[] = {0.00000002,2.0,2.0};
  double s[] = {10.0,10.0};
  CAlglib::MinCGSetScale(state,s);

  double epsg = 0.0000000001;
  double epsf = 0;
  double epsx = 0;
  int maxits = 20;

  CAlglib::MinCGSetCond(state, epsg, epsf, epsx, maxits);

  class Evaluator : public CNDimensional_Func
  {
  protected:
    nvVecd _prices;
    double _bestProfit;
    double _bestDD;
    double _bestCost;

  public:
    Evaluator() {
      _prices = nv_read_vecd("eur_prices.txt");
      _bestCost = 1e10;
      _bestDD = 0.0;
      _bestProfit = 0.0;
    }

    virtual void Func(double &x[],double &func,CObject &obj)
    {
      logDEBUG("Training with x="<<x);

      double tcost = 0.000001;
      nvRRLStrategyDry strategy(tcost, 10, (int)floor(x[0]+0.5), (int)floor(x[1]+0.5), _Symbol,_Period);
      strategy.setMaxIterations(20);

      nvVecd rets;

      strategy.dryrun(GetPointer(_prices),GetPointer(rets));

      // Build the wealth vector:
      uint num = rets.size();
      nvVecd wealth(num);
      double total = 0.0;
      for(uint i=0;i<num-1;++i) {
        total += rets[i];
        wealth.set(i+1,total);
      }

      logDEBUG("Final profit: "<<total);

      // Compute the maximum drawndown:
      double max_dd, dd, max_price, wi;
      max_dd=dd=max_price=wi=0.0;

      for(uint i=0;i<num;++i)
      {
        wi=wealth[i];
        if(wi>max_price) {
          // Assign the current max drawndown:
          max_dd = MathMax(max_dd,dd);
          dd = 0.0;
          max_price = wi;
        }
        else {
          dd=MathMax(dd,max_price-wi);
        }
      }
      logDEBUG("Max drawndown: "<< max_dd);

      func=-total/max_dd;

      if(func <_bestCost) {
        _bestProfit = total;
        _bestDD = max_dd;
        _bestCost = func;
      }

      logDEBUG("Global cost: "<<func);
    };

    double getBestProfit() const
    {
      return _bestProfit;
    }

    double getBestCost() const
    {
      return _bestCost;
    }

    double getBestDrawnDown() const
    {
      return _bestDD;
    }
  };

  Evaluator ev;
  CNDimensional_Rep rep;

  CObject obj;
  logDEBUG("Starting optimization...");
  CAlglib::MinCGOptimize(state,ev,rep,true,obj);
  logDEBUG("Optimization done.");

  CMinCGReportShell res;
  CAlglib::MinCGResults(state, x, res);

  DISPLAY(x);
  
  logDEBUG("Best cost: "<<ev.getBestCost()<<", bestProfit: "<<ev.getBestProfit()<<", best DrawnDown: "<<ev.getBestDrawnDown());

  //ev.Grad(x,fx,grad,obj);
  //DISPLAY(fx);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
