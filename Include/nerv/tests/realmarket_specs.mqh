
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/RealMarket.mqh>

BEGIN_TEST_PACKAGE(realmarket_specs)

BEGIN_TEST_SUITE("RealMarket class")

BEGIN_TEST_CASE("should be able to create a RealMarket instance")
	nvRealMarket market;
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide info on open position status")
  nvPortfolioManager* man = nvPortfolioManager::instance();
  nvMarket* market = man.getMarket(MARKET_TYPE_REAL);

  ASSERT_EQUAL((int)market.getMarketType(),(int)MARKET_TYPE_REAL);

  // No open position by default:
  ASSERT_EQUAL(market.hasOpenPosition("EURUSD"),false)
  man.reset();

END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
