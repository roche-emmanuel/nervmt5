
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trades.mqh>

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
  nvRRLModel model(M);
  nvVecd returns = nv_read_vecd("retDAX.txt");

  nvVecd nrets = returns.stdnormalize();

  returns = returns.subvec(0,M+T);
  nrets = nrets.subvec(0,M+T);

  //DISPLAY(returns.subvec(0,10));
  //DISPLAY(nrets.subvec(0,10));

  REQUIRE_EQUAL(returns.size(),M+T);

  nvVecd grad(12);
  double delta = 0.001;

  double cost = model.costFunction(GetPointer(nrets),GetPointer(returns),delta,GetPointer(grad));

  DISPLAY(cost);
  DISPLAY(grad);  
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to train on DAX template")
  int M = 10;
  int T = 500;
  nvRRLModel model(M);
  nvVecd returns = nv_read_vecd("retDAX.txt");

  nvVecd nrets = returns.stdnormalize();

  returns = returns.subvec(0,M+T);
  nrets = nrets.subvec(0,M+T);

  //DISPLAY(returns.subvec(0,10));
  //DISPLAY(nrets.subvec(0,10));

  REQUIRE_EQUAL(returns.size(),M+T);

  nvVecd grad(12);
  double delta = 0.001;

  //double cost = model.costFunction(GetPointer(nrets),GetPointer(returns),delta,GetPointer(grad));
  nvVecd ratios;
  int nepochs = 30;
  model.train(GetPointer(returns),delta,nepochs,GetPointer(nrets),GetPointer(ratios));

  DISPLAY(ratios[0]);
  DISPLAY(ratios[nepochs-1]);
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
