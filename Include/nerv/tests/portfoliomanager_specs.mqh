
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/PortfolioManager.mqh>

BEGIN_TEST_PACKAGE(portfoliomanager_specs)

BEGIN_TEST_SUITE("PortfolioManager class")

BEGIN_TEST_CASE("should be able to retrieve the portfolio manager instance")
	nvPortfolioManager* man = nvPortfolioManager::instance();
	REQUIRE_VALID_PTR(man);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to check if a symbol is valid")
	nvPortfolioManager* man = nvPortfolioManager::instance();
  REQUIRE_EQUAL(man.isSymbolValid("XXXYYY"),false)
  REQUIRE_EQUAL(man.isSymbolValid("EURUSD"),true)
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to get a currency trader by symbol")
	nvPortfolioManager* man = nvPortfolioManager::instance();
	nvCurrencyTrader* ct = man.getCurrencyTrader("EURUSD");
	// There should be no currency trader with that symbol yet:
	REQUIRE_NULL_PTR(ct);

	BEGIN_REQUIRE_ERROR("")
		// Try adding an invalid currency symbol:
		ct = man.addCurrencyTrader("EURXXX");
		REQUIRE_NULL_PTR(ct);	  
	END_REQUIRE_ERROR()
	
	// Add a new valid currency trader:
	ct = man.addCurrencyTrader("EURUSD");
	REQUIRE_VALID_PTR(ct);

	// Check that we can retrieve the trader afterwards:
	ct = man.getCurrencyTrader("EURUSD");
	REQUIRE_VALID_PTR(ct);	

	// Now try adding a trader with the same symbol again:
	ct = man.addCurrencyTrader("EURUSD");
	REQUIRE_NULL_PTR(ct);

	// Finally we remove the trader:
	man.removeCurrencyTrader("EURUSD");

	// Then we should not have this trader anymore:
	ct = man.getCurrencyTrader("EURUSD");
	REQUIRE_NULL_PTR(ct)
	
END_TEST_CASE()

BEGIN_TEST_CASE("Should support handling multiple currencies")
	nvPortfolioManager* man = nvPortfolioManager::instance();
	man.addCurrencyTrader("EURUSD");
	man.addCurrencyTrader("GBPUSD");
	man.addCurrencyTrader("EURGBP");
	man.addCurrencyTrader("EURJPY");

	REQUIRE_EQUAL(man.getNumCurrencyTraders(),4)

	REQUIRE(man.removeCurrencyTrader("EURUSD"))
	REQUIRE_NULL(man.getCurrencyTrader("EURUSD"))

	// Should have 3 left:
	REQUIRE_EQUAL(man.getNumCurrencyTraders(),3)
	REQUIRE_NOT_NULL(man.getCurrencyTrader("GBPUSD"))
	REQUIRE_NOT_NULL(man.getCurrencyTrader("EURGBP"))
	REQUIRE_NOT_NULL(man.getCurrencyTrader("EURJPY"))

	REQUIRE(man.removeCurrencyTrader("EURGBP"))
	REQUIRE_NULL(man.getCurrencyTrader("EURGBP"))

	// Should have 2 left:
	REQUIRE_EQUAL(man.getNumCurrencyTraders(),2)
	REQUIRE_NOT_NULL(man.getCurrencyTrader("GBPUSD"))
	REQUIRE_NOT_NULL(man.getCurrencyTrader("EURJPY"))

	REQUIRE(man.removeCurrencyTrader("EURJPY"))
	REQUIRE_NULL(man.getCurrencyTrader("EURJPY"))

	// Should have 1 left:
	REQUIRE_EQUAL(man.getNumCurrencyTraders(),1)
	REQUIRE_NOT_NULL(man.getCurrencyTrader("GBPUSD"))

	// reset the portfolio:
	man.addCurrencyTrader("EURUSD");	
	man.removeAllCurrencyTraders();

	REQUIRE_EQUAL(man.getNumCurrencyTraders(),0)
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
