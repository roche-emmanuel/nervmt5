
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

	datetime time = TimeCurrent();
	deal.open(ct.getID(),ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
	deal.close(1.23457,time,10.0);

	// Send the deal to the CurrencyTrader:
	ct.onDeal(deal);

	// So, this is the first deal sent to the trader.
	// And there is only one trader, so its weight is always 1.0.
	// the new utility value should be:
	// profit = 10/2h = 5/h
	// dd = 0
	// u = mean_profit/(1+0) = 5.0
	REQUIRE_EQUAL(ct.getUtility(),5.0);
	REQUIRE_EQUAL(ct.getWeight(),1.0);
	
  // Reset the portfolio manager:
  nvPortfolioManager::instance().removeAllCurrencyTraders();
END_TEST_CASE()

BEGIN_TEST_CASE("Should compute its utility with 2 traders")
  nvPortfolioManager* man = nvPortfolioManager::instance();

  nvCurrencyTrader* ct0 = man.addCurrencyTrader("EURUSD");
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURJPY");
  
  // initial utility should be 0.0:
  ASSERT_EQUAL(ct.getUtility(),0.0);
  	
  // Now we generate a new deal:
  nvDeal* deal = new nvDeal();

	datetime time = TimeCurrent();
	deal.open(ct.getID(),ORDER_TYPE_BUY,1.23456,(int)time-3600*4,0.5);
	deal.close(1.23457,time-3600*2,10.0);

	// Send the deal to the CurrencyTrader:
	ct.onDeal(deal);

	// So, this is the first deal sent to the trader.
	// And there is only one trader, so its weight is always 1.0.
	// the new utility value should be:
	// profit = (10/2h) / lot = (10/2h)*2 = 10/h
	// dd = 0
	// u = mean_profit/(1+0) = 10.0
	ASSERT_EQUAL(ct.getUtility(),10.0);

	// The new weight should be:
	double w = MathExp(10.0)/(MathExp(0.0)+MathExp(10));
	ASSERT_CLOSEDIFF(ct.getWeight(),w,1e-8);
	ASSERT_CLOSEDIFF(ct0.getWeight(),1.0-w,1e-8);
	
	// TODO: add another deal here.
	deal = new nvDeal();

	deal.open(ct.getID(),ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
	deal.close(1.23457,time-3600,1.0);

	ct.onDeal(deal);

	// mean_profit = (10+1)/2
	// dd = 0
	// u = 5.5
	ASSERT_EQUAL(ct.getUtility(),5.5);
	w = MathExp(5.5)/(MathExp(0.0)+MathExp(5.5));
	ASSERT_CLOSEDIFF(ct.getWeight(),w,1e-8);
	ASSERT_CLOSEDIFF(ct0.getWeight(),1.0-w,1e-8);

	deal = new nvDeal();

	deal.open(ct.getID(),ORDER_TYPE_BUY,1.23456,(int)time-3600,2.0);
	deal.close(1.23457,time-1800,-4.0);

	ct.onDeal(deal);

	// nom_profit = -4 /2 /.5 = -4
	// mean_profit = (10+1-4)/3 = 7/3
	// dd = sqrt(4*4) = 4 
	// u = 3.5/(1.0+4)
	double u = (7.0/3.0)/(1.0+4);
	ASSERT_EQUAL(ct.getUtility(),u);
	w = MathExp(u)/(MathExp(0.0)+MathExp(u));
	ASSERT_CLOSEDIFF(ct.getWeight(),w,1e-8);
	ASSERT_CLOSEDIFF(ct0.getWeight(),1.0-w,1e-8);

  // Reset the portfolio manager:
  nvPortfolioManager::instance().removeAllCurrencyTraders();
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
