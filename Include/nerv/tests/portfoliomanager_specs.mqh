
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
  REQUIRE_EQUAL(man.isSymbolValid("XXXYYY"),false);
  REQUIRE_EQUAL(man.isSymbolValid("EURUSD"),true);
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
	REQUIRE_NULL_PTR(ct);
	
END_TEST_CASE()

BEGIN_TEST_CASE("Should support handling multiple currencies")
	nvPortfolioManager* man = nvPortfolioManager::instance();
	man.addCurrencyTrader("EURUSD");
	man.addCurrencyTrader("GBPUSD");
	man.addCurrencyTrader("EURGBP");
	man.addCurrencyTrader("EURJPY");

	REQUIRE_EQUAL(man.getNumCurrencyTraders(),4);

	REQUIRE(man.removeCurrencyTrader("EURUSD"));
	REQUIRE_NULL(man.getCurrencyTrader("EURUSD"));

	// Should have 3 left:
	REQUIRE_EQUAL(man.getNumCurrencyTraders(),3);
	REQUIRE_NOT_NULL(man.getCurrencyTrader("GBPUSD"));
	REQUIRE_NOT_NULL(man.getCurrencyTrader("EURGBP"));
	REQUIRE_NOT_NULL(man.getCurrencyTrader("EURJPY"));

	REQUIRE(man.removeCurrencyTrader("EURGBP"));
	REQUIRE_NULL(man.getCurrencyTrader("EURGBP"));

	// Should have 2 left:
	REQUIRE_EQUAL(man.getNumCurrencyTraders(),2);
	REQUIRE_NOT_NULL(man.getCurrencyTrader("GBPUSD"));
	REQUIRE_NOT_NULL(man.getCurrencyTrader("EURJPY"));

	REQUIRE(man.removeCurrencyTrader("EURJPY"));
	REQUIRE_NULL(man.getCurrencyTrader("EURJPY"));

	// Should have 1 left:
	REQUIRE_EQUAL(man.getNumCurrencyTraders(),1);
	REQUIRE_NOT_NULL(man.getCurrencyTrader("GBPUSD"));

	// reset the portfolio:
	man.addCurrencyTrader("EURUSD");	
	man.removeAllCurrencyTraders();

	REQUIRE_EQUAL(man.getNumCurrencyTraders(),0);
END_TEST_CASE()

BEGIN_TEST_CASE("Should allow updating the currency traders weights")
  // Should have no effect when contains no currency trader:
	nvPortfolioManager* man = nvPortfolioManager::instance();
	man.updateWeights();

	// Should set its initial weight to one when there is only one currency:
	// But note that the weight should be updated automatically in that case:
	nvCurrencyTrader* ct = man.addCurrencyTrader("EURJPY");
	ASSERT_NOT_NULL(ct);
	ASSERT_EQUAL(ct.getWeight(),1.0);
	
	// When adding a new currency trader the weights should be updated:
	nvCurrencyTrader* ct2 = man.addCurrencyTrader("GBPUSD");
	ASSERT_NOT_NULL(ct2);
	ASSERT_EQUAL(ct.getWeight(),0.5);
	ASSERT_EQUAL(ct2.getWeight(),0.5);

	// reset the current status:
	man.removeAllCurrencyTraders();
	ASSERT_EQUAL(man.getNumCurrencyTraders(),0);	
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide new unique IDs")
  nvPortfolioManager* man = nvPortfolioManager::instance();
  int id1 = man.getNewID();
  int id2 = man.getNewID();
  REQUIRE_EQUAL(id1+1,id2);
  REQUIRE_GE(id1,10000);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to retrieve a currency trader by ID")
	nvPortfolioManager* man = nvPortfolioManager::instance();
	nvCurrencyTrader* ct1 = man.addCurrencyTrader("EURUSD");
	REQUIRE_NOT_NULL(ct1);
	nvCurrencyTrader* ct2 = man.addCurrencyTrader("GBPUSD");
	REQUIRE_NOT_NULL(ct2);
	nvCurrencyTrader* ct3 = man.addCurrencyTrader("EURGBP");
	REQUIRE_NOT_NULL(ct3);

	REQUIRE_EQUAL(ct2.getID(),ct1.getID()+1);
	REQUIRE_EQUAL(ct3.getID(),ct2.getID()+1);

	nvCurrencyTrader* ct1b = man.getCurrencyTraderByID(ct1.getID());
	nvCurrencyTrader* ct2b = man.getCurrencyTraderByID(ct2.getID());
	nvCurrencyTrader* ct3b = man.getCurrencyTraderByID(ct3.getID());

	REQUIRE_EQUAL(ct1,ct1b);
	REQUIRE_EQUAL(ct2,ct2b);
	REQUIRE_EQUAL(ct3,ct3b);
	
	REQUIRE_EQUAL(ct2.getID(),ct2b.getID());

	// reset the current status:
	man.removeAllCurrencyTraders();	
END_TEST_CASE()

BEGIN_TEST_CASE("Should have a method reset to remove everything")
  nvPortfolioManager* man = nvPortfolioManager::instance();
	nvCurrencyTrader* ct1 = man.addCurrencyTrader("EURUSD");
	REQUIRE_NOT_NULL(ct1);
	nvCurrencyTrader* ct2 = man.addCurrencyTrader("GBPUSD");
	REQUIRE_NOT_NULL(ct2);

	man.reset();

	ASSERT(!IS_VALID_POINTER(ct1));
	ASSERT(!IS_VALID_POINTER(ct2));
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide a risk manager instance")
	nvPortfolioManager* man = nvPortfolioManager::instance();
	nvRiskManager* rman = man.getRiskManager();
	ASSERT_NOT_NULL(rman);
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide a random generator")
  nvPortfolioManager* man = nvPortfolioManager::instance();
  SimpleRNG* rnd = man.getRandomGenerator();
  ASSERT_NOT_NULL(rnd);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
