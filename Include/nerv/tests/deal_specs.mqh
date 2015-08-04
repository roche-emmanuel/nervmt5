
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/Deal.mqh>

BEGIN_TEST_PACKAGE(deal_specs)

BEGIN_TEST_SUITE("nvDeal class")

BEGIN_TEST_CASE("Should be able to create a new Deal object")
	nvDeal deal;
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide trader ID")
  nvDeal deal;

  // By default TRADER ID should be invalid:
  REQUIRE_EQUAL(deal.getTraderID(),(int)INVALID_TRADER_ID);
  
  // Should throw an error if we use an invalid ID:
	BEGIN_REQUIRE_ERROR("Invalid trader ID")
	  deal.setTraderID(1);
	END_REQUIRE_ERROR();

  // Should also throw an error if the ID is valid, but the currency trader is not 
  // registered:
	BEGIN_REQUIRE_ERROR("Invalid trader ID")
	  nvCurrencyTrader ct("EURPJY");
	  deal.setTraderID(ct.getID());
	END_REQUIRE_ERROR();

	// Should not throw if the currency trader is properly registered:
	nvCurrencyTrader* ct = nvPortfolioManager::instance().addCurrencyTrader("EURJPY");
	deal.setTraderID(ct.getID());
  REQUIRE_EQUAL(deal.getTraderID(),ct.getID());

  // Reset the content:
  nvPortfolioManager::instance().removeAllCurrencyTraders();
END_TEST_CASE()

BEGIN_TEST_CASE("Should also provide a number of points of profit")
  nvDeal deal;

  // Default profit is 0.0:
  REQUIRE_EQUAL(deal.getNumPoints(),0.0);
  
  // Set the number of profit points:
  deal.setNumPoints(0.12345);
  REQUIRE_EQUAL(deal.getNumPoints(),0.12345);
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide the profit value")
  nvDeal deal;

  // Default profit is 0.0:
  REQUIRE_EQUAL(deal.getProfit(),0.0);
  
  // Set the number of profit points:
  deal.setProfit(10.12);
  REQUIRE_EQUAL(deal.getProfit(),10.12);
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide the list of utilities from all traders")
  nvDeal deal;

  // no utility values by default:
  double list[];
  deal.getUtilities(list);
  REQUIRE_EQUAL(ArraySize(list),0);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
