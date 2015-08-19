
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/VirtualMarket.mqh>

BEGIN_TEST_PACKAGE(virtualmarket_specs)

BEGIN_TEST_SUITE("VirtualMarket class")

BEGIN_TEST_CASE("should be able to create a VirtualMarket instance")
	nvVirtualMarket vmarket;
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide info on open position status")
  nvPortfolioManager* man = nvPortfolioManager::instance();
  nvMarket* market = man.getMarket(MARKET_TYPE_VIRTUAL);

  ASSERT_EQUAL((int)market.getMarketType(),(int)MARKET_TYPE_VIRTUAL);

  // No open position by default:
  ASSERT_EQUAL(market.hasOpenPosition("EURUSD"),false)
  man.reset();

END_TEST_CASE()

BEGIN_TEST_CASE("Should allow retrieving position type")
  // For the moment this will just throw an error:
  nvVirtualMarket market;
  ASSERT_EQUAL((int)market.getPositionType("EURUSD"),(int)POS_NONE);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
