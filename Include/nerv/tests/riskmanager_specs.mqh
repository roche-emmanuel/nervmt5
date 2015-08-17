
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/RiskManager.mqh>

BEGIN_TEST_PACKAGE(riskmanager_specs)

BEGIN_TEST_SUITE("RiskManager class")

BEGIN_TEST_CASE("should be able to create a RiskManager instance")
	nvRiskManager rman;
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to set/get risk level")
  nvRiskManager* rman = nvPortfolioManager::instance().getRiskManager();

  // Default value for the risk level should be of 2%
  ASSERT_EQUAL(rman.getRiskLevel(),0.02);

  rman.setRiskLevel(0.03);
  ASSERT_EQUAL(rman.getRiskLevel(),0.03);
  
  // When reseting the manager, the risk level should be reinitialized:
  nvPortfolioManager::instance().reset();
  ASSERT_EQUAL(rman.getRiskLevel(),0.02);
END_TEST_CASE()

BEGIN_TEST_CASE("Should detect the account currency properly")
  nvRiskManager* rman = nvPortfolioManager::instance().getRiskManager();

  ASSERT_EQUAL(rman.getAccountCurrency(),"EUR");
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to retrieve a balanace value")
  nvRiskManager* rman = nvPortfolioManager::instance().getRiskManager();

  double balance = AccountInfoDouble(ACCOUNT_BALANCE);
  ASSERT_EQUAL(rman.getBalanceValue("EUR"),balance);

  // Check the balance value in USD:
  MqlTick latest_price;
  SymbolInfoTick("EURUSD",latest_price);
  ASSERT_EQUAL(rman.getBalanceValue("USD"),balance*latest_price.bid);

  SymbolInfoTick("EURJPY",latest_price);
  ASSERT_EQUAL(rman.getBalanceValue("JPY"),balance*latest_price.bid);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
