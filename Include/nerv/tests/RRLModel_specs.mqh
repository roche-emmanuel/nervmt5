
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

BEGIN_TEST_CASE("should be able to train on some data")
  int ni = 10;
  string symbol = "EURUSD";
  ENUM_TIMEFRAMES period = PERIOD_M1;

  nvRRLModel model(ni);  

  // Retrieve the data we need:
  int ns = 1000+ni-1;

  // Initialize the price return vector:
  nvVecd returns = nv_get_return_prices(ns,symbol,period);

  REQUIRE_EQUAL(returns.size(),ns);
  
  double sr = model.train_batch(GetPointer(returns),0.0008);
  DISPLAY(sr);
  REQUIRE(MathAbs(sr)<1.0);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
