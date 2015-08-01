
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/PortfolioManager.mqh>

BEGIN_TEST_PACKAGE(portfoliomanager_specs)

BEGIN_TEST_SUITE("PortfolioManager class")

BEGIN_TEST_CASE("should be able to retrieve the portfolio manager instance")
	nvPortfolioManager* man = nvPortfolioManager::instance();
	REQUIRE_VALID_PTR(man);
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to get a currency trader by symbol")
	nvPortfolioManager* man = nvPortfolioManager::instance();
	nvCurrencyTrader* ct = man.getCurrencyTrader("EURUSD");
	// There should be no currency trader with that symbol yet:
	REQUIRE_NULL_PTR(ct);

	// Try adding an invalid currency symbol:
	ct = man.addCurrencyTrader("EURXXX");
	REQUIRE_NULL_PTR(ct);

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
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
