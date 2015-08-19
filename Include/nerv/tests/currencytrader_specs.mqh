
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/CurrencyTrader.mqh>

BEGIN_TEST_PACKAGE(currencytrader_specs)

BEGIN_TEST_SUITE("CurrencyTrader class")

BEGIN_TEST_CASE("should be able to create a CurrencyTrader instance")
	nvCurrencyTrader ct;
	ct.setSymbol("EURUSD");
	ASSERT_EQUAL(ct.getSymbol(),"EURUSD");
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide access to its utility value")
  nvCurrencyTrader ct;
  ct.setSymbol("EURUSD");
  // By default the utility value should be 0.0:
  ASSERT_EQUAL(ct.getUtility(),0.0);
END_TEST_CASE()

BEGIN_TEST_CASE("Should increment the unique ID properly")
  nvPortfolioManager man;
  nvCurrencyTrader ct;
  ct.setSymbol("EURUSD");
  ct.setManager(man);
  nvCurrencyTrader ct2;
  ct2.setSymbol("EURJPY");
  ct2.setManager(man);
  
  ASSERT_EQUAL(ct.getID(),10000);

  ASSERT_EQUAL(ct2.getID(),ct.getID()+1);
END_TEST_CASE()

BEGIN_TEST_CASE("Should compute its utility each time a deal is received")
  nvPortfolioManager* man = nvPortfolioManager::instance();

  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  
  // initial utility should be 0.0:
  ASSERT_EQUAL(ct.getUtility(),0.0);
  	
  // Now we generate a new deal:
  nvDeal* deal = new nvDeal();

	datetime time = TimeCurrent();
	deal.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
	deal.close(1.23457,time,10.0);

	// Send the deal to the CurrencyTrader:
	ct.onDeal(deal);

	// So, this is the first deal sent to the trader.
	// And there is only one trader, so its weight is always 1.0.
	// the new utility value should be:
	// profit = 10/2h = 5/h
	// dd = 0
	// u = mean_profit/(1+0) = 5.0
	ASSERT_EQUAL(ct.getUtility(),5.0);
	ASSERT_EQUAL(ct.getWeight(),1.0);
	
  // Reset the portfolio manager:
  man.reset();
END_TEST_CASE()

BEGIN_TEST_CASE("Should compute its utility with 2 traders")
  nvPortfolioManager* man = nvPortfolioManager::instance();

  nvCurrencyTrader* ct0 = man.addCurrencyTrader("EURUSD");
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURJPY");

	ASSERT(ct!=NULL);
	ASSERT(ct0!=NULL);

  // initial utility should be 0.0:
  ASSERT_EQUAL(ct.getUtility(),0.0);
  	
  // Now we generate a new deal:
  nvDeal* deal = new nvDeal();

	datetime time = TimeCurrent();
	deal.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*4,0.5);
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
	// dev if utility is zero, so the weight element should always be 1.0
	// double w = MathExp(10.0)/(MathExp(0.0)+MathExp(10));
	double w = 1.0/2.0;
	ASSERT_CLOSEDIFF(ct.getWeight(),w,1e-8);
	ASSERT_CLOSEDIFF(ct0.getWeight(),1.0-w,1e-8);
	
	deal = new nvDeal();

	deal.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
	deal.close(1.23457,time-3600,1.0);

	ct.onDeal(deal);

	// mean_profit = (10+1)/2
	// dd = 0
	// u = 5.5
	ASSERT_EQUAL(ct.getUtility(),5.5);
	double alpha = man.getUtilityEfficiency();
	double m = man.getUtilityMean();
	double dev = man.getUtilityDeviation();
	dev = dev==0.0 ? 1.0 : dev;
	w = MathExp(alpha*(5.5-m)/dev)/(MathExp(alpha*(0.0-m)/dev)+MathExp(alpha*(5.5-m)/dev));
	ASSERT_CLOSEDIFF(ct.getWeight(),w,1e-8);
	ASSERT_CLOSEDIFF(ct0.getWeight(),1.0-w,1e-8);

	deal = new nvDeal();

	deal.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600,2.0);
	deal.close(1.23457,time-1800,-4.0);

	ct.onDeal(deal);

	// nom_profit = -4 /2 /.5 = -4
	// mean_profit = (10+1-4)/3 = 7/3
	// dd = sqrt(4*4) = 4 
	// u = 3.5/(1.0+4)
	double u = (7.0/3.0)/(1.0+4);
	ASSERT_EQUAL(ct.getUtility(),u);
	alpha = man.getUtilityEfficiency();
	m = man.getUtilityMean();
	dev = man.getUtilityDeviation();
	dev = dev==0.0 ? 1.0 : dev;
	w = MathExp(alpha*(u-m)/dev)/(MathExp(alpha*(0.0-m)/dev)+MathExp(alpha*(u-m)/dev));
	ASSERT_CLOSEDIFF(ct.getWeight(),w,1e-8);
	ASSERT_CLOSEDIFF(ct0.getWeight(),1.0-w,1e-8);

  // Reset the portfolio manager:
  man.reset();
END_TEST_CASE()

BEGIN_TEST_CASE("Should release the deals it contains on deletion.")
  nvPortfolioManager* man = nvPortfolioManager::instance();

  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");

	datetime time = TimeCurrent();

  nvDeal* d1 = new nvDeal();
	d1.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*4,0.5);
	d1.close(1.23457,time-3600*2,10.0);
	ct.onDeal(d1);

	nvDeal* d2 = new nvDeal();
	d2.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
	d2.close(1.23457,time-3600,1.0);
	ct.onDeal(d2);

  man.reset();

  ASSERT(!IS_VALID_POINTER(d1));
	ASSERT(!IS_VALID_POINTER(d2));
END_TEST_CASE()

BEGIN_TEST_CASE("Should support collecting deals")
  
  nvPortfolioManager* man = nvPortfolioManager::instance();

  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");

	datetime time = TimeCurrent();

  nvDeal* d1 = new nvDeal();
	d1.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*4,0.5);
	d1.close(1.23457,time-3600*2,10.0);
	ct.onDeal(d1);

	nvDeal* d2 = new nvDeal();
	d2.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
	d2.close(1.23457,time-3600,1.0);
	ct.onDeal(d2);

	nvDeal* d3 = new nvDeal();
	d3.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600,1.0);
	d3.close(1.23457,time-1800,1.0);
	ct.onDeal(d3);

	nvDeal* list[];
	ASSERT_EQUAL(ct.collectDeals(list,time-3600*3,time-1000),2);

	int num = ArraySize( list );
	ASSERT_EQUAL(num,2);
	ASSERT_EQUAL(d2,list[0]);
	ASSERT_EQUAL(d3,list[1]);

	// If we call the same method again the deals should be appended again:
	ASSERT_EQUAL(ct.collectDeals(list,time-3600*3,time-1000),2);
	num = ArraySize( list );
	ASSERT_EQUAL(num,4);
	
  man.reset();
END_TEST_CASE()

BEGIN_TEST_CASE("Should not have an open position by default.")
  nvPortfolioManager* man = nvPortfolioManager::instance();
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  ASSERT_EQUAL(ct.hasOpenPosition(),false);
  man.reset();
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to close a position")
  nvPortfolioManager* man = nvPortfolioManager::instance();
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  ct.setMarketType(MARKET_TYPE_VIRTUAL);
  ct.openPosition(0.5);
  ASSERT_EQUAL(ct.hasOpenPosition(),true);
  int count = ct.getDealCount();
  ASSERT_EQUAL(count,0);
  
  ct.closePosition();
  ASSERT_EQUAL(ct.hasOpenPosition(),false);

	// Should have received one additional deal:
  ASSERT_EQUAL(ct.getDealCount(),count+1);
  
  man.reset();
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
