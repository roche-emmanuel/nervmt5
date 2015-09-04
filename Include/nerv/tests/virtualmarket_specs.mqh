
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/VirtualMarket.mqh>

BEGIN_TEST_PACKAGE(virtualmarket_specs)

BEGIN_TEST_SUITE("VirtualMarket class")

BEGIN_TEST_CASE("should be able to create a VirtualMarket instance")
	nvVirtualMarket vmarket;
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide info on open position status")
  nvPortfolioManager man;
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

BEGIN_TEST_CASE("Should provide the value of the balance")
  nvPortfolioManager man;
  nvVirtualMarket* market = (nvVirtualMarket*)man.getMarket(MARKET_TYPE_VIRTUAL);
  
  // Assign a balance value:
  market.setBalance(2001.0);

  double balance = market.getBalance("EUR");

  // Compare with the assigned balance value:
  ASSERT_EQUAL(balance,2001.0);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
