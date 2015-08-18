
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/VirtualMarket.mqh>

BEGIN_TEST_PACKAGE(virtualmarket_specs)

BEGIN_TEST_SUITE("VirtualMarket class")

BEGIN_TEST_CASE("should be able to create a VirtualMarket instance")
	nvVirtualMarket vmarket;
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide info on open position status")
  nvPortfolioManager* man = nvPortfolioManager::instance();
  nvVirtualMarket* vmark = man.getVirtualMarket();

  // No open position by default:
  ASSERT_EQUAL(vmark.hasOpenPosition("EURUSD"),false)
  man.reset();

END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
