
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trade/RRLStrategy.mqh>

BEGIN_TEST_PACKAGE(rrlstrategy_specs)

BEGIN_TEST_SUITE("RRLStrategy class")

BEGIN_TEST_CASE("should be able to create a strategy object")
  nvRRLStrategy* st = new nvRRLStrategy(10, 0.01, 0.01, 1.0, 2.0,"EURUSD",PERIOD_M1);  
  REQUIRE(st!=NULL);
  delete st;
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
