
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/RiskManager.mqh>

BEGIN_TEST_PACKAGE(riskmanager_specs)

BEGIN_TEST_SUITE("RiskManager class")

BEGIN_TEST_CASE("should be able to create a RiskManager instance")
	nvRiskManager rman;
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to set/get risk level")
  nvPortfolioManager man;
  nvRiskManager* rman = man.getRiskManager();

  // Default value for the risk level should be of 2%
  ASSERT_EQUAL(rman.getRiskLevel(),0.02);

  rman.setRiskLevel(0.03);
  ASSERT_EQUAL(rman.getRiskLevel(),0.03);
  
  // When reseting the manager, the risk level should be reinitialized:
  man.reset();
  ASSERT_EQUAL(rman.getRiskLevel(),0.02);
END_TEST_CASE()

BEGIN_TEST_CASE("Should detect the account currency properly")
  nvPortfolioManager man;
  nvRiskManager* rman = man.getRiskManager();

  ASSERT_EQUAL(rman.getAccountCurrency(),"EUR");
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to retrieve a balance value")
  nvPortfolioManager man;
  nvRiskManager* rman = man.getRiskManager();

  double balance = AccountInfoDouble(ACCOUNT_BALANCE);
  ASSERT_EQUAL(rman.getBalanceValue("EUR"),balance);

  // Check the balance value in USD:
  MqlTick latest_price;
  double bid;
  
  if(SymbolInfoTick("EURUSD",latest_price)) {
    bid = latest_price.bid;
  }
  else {
    // previous call might fail:
    // we rely on the price manager in that case:
    bid = man.getPriceManager().getBidPrice("EURUSD");
  }
  ASSERT_EQUAL(rman.getBalanceValue("USD"),balance*bid);

  if(SymbolInfoTick("EURJPY",latest_price)) {
    bid = latest_price.bid;
  }
  else {
    // previous call might fail:
    // we rely on the price manager in that case:
    bid = man.getPriceManager().getBidPrice("EURJPY");
  }
  ASSERT_EQUAL(rman.getBalanceValue("JPY"),balance*bid);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to evaluate a lot size")
  nvPortfolioManager man;
  nvRiskManager* rman = man.getRiskManager();
  nvMarket* market = man.getMarket(MARKET_TYPE_REAL);

  double balance = market.getBalance("JPY");
	
	double var = balance*0.03*0.5*0.8;
	double mylot = var/(100.0*30.0);

	rman.setRiskLevel(0.03);
	double lot = rman.evaluateLotSize(market,"EURJPY",30.0,0.5,0.8);
  // Todo: should use the maxlot size here.
  // double maxlot = rman.computeMaxLotSize(symbol,confidence);

	ASSERT_EQUAL(lot,MathFloor(mylot/0.01)*0.01);

  balance = market.getBalance("CAD");
	
	var = balance*0.03*0.2*0.6;
	mylot = var/(1.0*50.0);
	lot = rman.evaluateLotSize(market,"EURCAD",50.0,0.2,0.6);
	ASSERT_EQUAL(lot,MathFloor(mylot/0.01)*0.01);

	man.reset();  
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
