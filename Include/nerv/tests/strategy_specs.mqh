
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trade/Strategy.mqh>

BEGIN_TEST_PACKAGE(strategy_specs)

BEGIN_TEST_SUITE("Strategy class")

BEGIN_TEST_CASE("should be able to create a strategy object")
  nvStrategy* st = new nvStrategy("EURUSD",PERIOD_M1);  
  REQUIRE(st!=NULL);
  delete st;
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
