
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/CurrencyTrader.mqh>

BEGIN_TEST_PACKAGE(currencytrader_specs)

BEGIN_TEST_SUITE("CurrencyTrader class")

BEGIN_TEST_CASE("should be able to create a CurrencyTrader instance")
	nvCurrencyTrader ct("EURUSD");
	REQUIRE_EQUAL(ct.getSymbol(),"EURUSD");
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide access to its utility value")
  nvCurrencyTrader ct("EURUSD");
  // By default the utility value should be 0.0:
  REQUIRE_EQUAL(ct.getUtility(),0.0);
END_TEST_CASE()

BEGIN_TEST_CASE("Should increment the unique ID properly")
  nvCurrencyTrader ct("EURUSD");
  nvCurrencyTrader ct2("EURJPY");
  
  REQUIRE_EQUAL(ct2.getID(),ct.getID()+1);
END_TEST_CASE()

BEGIN_TEST_CASE("Should compute its utility each time a deal is received")
  nvPortfolioManager* man = nvPortfolioManager::instance();

  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  
  // initial utility should be 0.0:
  REQUIRE_EQUAL(ct.getUtility(),0.0);
  	
  // Now we generate a new deal:
  nvDeal* deal = new nvDeal();

	datetime time = TimeLocal();
	deal.open(ct.getID(),ORDER_TYPE_BUY,1.23456,time);
	deal.close(1.23457,time+3600,10.0);

	// Send the deal to the CurrencyTrader:
	ct.onDeal(deal);

  // Reset the portfolio manager:
  nvPortfolioManager::instance().removeAllCurrencyTraders();
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
