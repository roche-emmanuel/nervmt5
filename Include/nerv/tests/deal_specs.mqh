
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/CurrencyTrader.mqh>
#include <nerv/expert/Deal.mqh>

BEGIN_TEST_PACKAGE(deal_specs)

BEGIN_TEST_SUITE("nvDeal class")

BEGIN_TEST_CASE("Should be able to create a new Deal object")
	nvDeal deal;
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide trader ID")
  nvDeal deal;

  // By default TRADER ID should be invalid:
  BEGIN_ASSERT_ERROR("Invalid currency trader.")
    deal.getCurrencyTrader();
  END_ASSERT_ERROR();
    
  // Should throw an error if we use an invalid ID:
	BEGIN_ASSERT_ERROR("Invalid currency trader.")
	  deal.setCurrencyTrader(NULL);
	END_ASSERT_ERROR();
   
   nvPortfolioManager man;
   
  // Should also throw an error if the ID is valid, but the currency trader is not 
  // registered:
	// BEGIN_ASSERT_ERROR("Invalid trader ID")
	//   nvCurrencyTrader ct;
	//   ct.setSymbol("EURPJY");
	//   ct.setManager(man);
	//   deal.setCurrencyTrader(GetPointer(ct));
	// END_ASSERT_ERROR();

	// Should not throw if the currency trader is properly registered:
	nvCurrencyTrader* ct = man.addCurrencyTrader("EURJPY");
	deal.setCurrencyTrader(ct);
  ASSERT_EQUAL(deal.getCurrencyTrader().getID(),ct.getID());

  // Reset the content:
  man.reset();
END_TEST_CASE()

BEGIN_TEST_CASE("Should also provide a number of points of profit")
  nvDeal deal;

  // Default profit is 0.0:
  ASSERT_EQUAL(deal.getNumPoints(),0.0);
  
  // Set the number of profit points:
  deal.setNumPoints(0.12345);
  ASSERT_EQUAL(deal.getNumPoints(),0.12345);
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide the profit value")
  nvDeal deal;

  // Default profit is 0.0:
  ASSERT_EQUAL(deal.getProfit(),0.0);
  
  // Set the number of profit points:
  deal.setProfit(10.12);
  ASSERT_EQUAL(deal.getProfit(),10.12);
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide the list of utilities from all traders")
  nvDeal deal;

  // no utility values by default:
  double list[];
  deal.getUtilities(list);
  ASSERT_EQUAL(ArraySize(list),0);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to open a deal")
  nvDeal deal;

  nvPortfolioManager man;
  man.addCurrencyTrader("EURUSD");
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURJPY");

  datetime time = TimeLocal();
  deal.open(ct,ORDER_TYPE_BUY,1.23456,time,1.0);

  ASSERT_EQUAL(deal.getEntryPrice(),1.23456);
  ASSERT_EQUAL(deal.getEntryTime(),time);

  double list[];
  deal.getUtilities(list);
  ASSERT_EQUAL(ArraySize(list),2);
  ASSERT_EQUAL(list[0],0.0);
  ASSERT_EQUAL(list[1],0.0);
  
  // Reset the content:
  man.reset();	
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to close a deal and update number of points")
  nvDeal deal;

  nvPortfolioManager man;
  man.addCurrencyTrader("EURUSD");
	nvCurrencyTrader* ct = man.addCurrencyTrader("EURJPY");

	datetime time = TimeLocal();
	deal.open(ct,ORDER_TYPE_BUY,1.23456,time,1.0);

	// Now close the deal:
	deal.close(1.23457,time+1,12.3);

	ASSERT_EQUAL(deal.getExitPrice(),1.23457);
	ASSERT_EQUAL(deal.getExitTime(),time+1);
	ASSERT_EQUAL(deal.getProfit(),12.3);
	
	ASSERT_EQUAL(NormalizeDouble(deal.getNumPoints(),5),0.00001);
	
  // Reset the content:
  man.reset();	
END_TEST_CASE()

BEGIN_TEST_CASE("Should not be done until it is closed")
  nvDeal deal;

  nvPortfolioManager man;
  man.addCurrencyTrader("EURUSD");
	nvCurrencyTrader* ct = man.addCurrencyTrader("EURJPY");

	ASSERT_EQUAL(deal.isDone(),false);
	
	datetime time = TimeLocal();
	deal.open(ct,ORDER_TYPE_BUY,1.23456,time,1.0);

	ASSERT_EQUAL(deal.isDone(),false);
	
	// Now close the deal:
	deal.close(1.23457,time+1,10.0);

	ASSERT_EQUAL(deal.isDone(),true);
	
  // Reset the content:
  man.reset();	  
END_TEST_CASE()

BEGIN_TEST_CASE("Should throw an error if trying to close an non opened deal")
  nvDeal deal;

	BEGIN_ASSERT_ERROR("Cannot close not opened deal")
	  deal.close(1.23457,TimeLocal(),10.0);
	END_ASSERT_ERROR();
END_TEST_CASE()

BEGIN_TEST_CASE("Should support computing the weight derivative")
  nvPortfolioManager man;

  nvCurrencyTrader* ct = man.addCurrencyTrader("EURJPY");
  nvCurrencyTrader* ct2 = man.addCurrencyTrader("EURUSD");
  
  // initial utility should be 0.0:
  ASSERT_EQUAL(ct.getUtility(),0.0);
    
  // Now we generate a new deal:
  nvDeal* deal = new nvDeal();

  datetime time = TimeCurrent();
  deal.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*4,0.5);
  deal.close(1.23457,time-3600*2,10.0);
  deal.setMarketType(ct.getMarketType());

  // Send the deal to the CurrencyTrader:
  ct.onDeal(deal);

  // Initially the utility is 0 for both currency:
  double d = deal.getProfitDerivative(1.0);
  ASSERT_EQUAL(d,0.0);

  // So, this is the first deal sent to the trader.
  // And there is only one trader, so its weight is always 1.0.
  // the new utility value should be:
  // profit = (10/2h) / lot = (10/2h)*2 = 10/h
  // dd = 0
  // u = mean_profit/(1+0) = 10.0
  ASSERT_EQUAL(ct.getUtility(),10.0);

  // The new weight should be:
  // double w = MathExp(10.0)/(MathExp(0.0)+MathExp(10));
  double w = 1.0/2.0;
  ASSERT_CLOSEDIFF(ct.getWeight(),w,1e-8);
  ASSERT_CLOSEDIFF(ct2.getWeight(),1.0-w,1e-8);
  
  deal = new nvDeal();

  deal.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
  deal.close(1.23457,time-3600,1.0);
  deal.setMarketType(ct.getMarketType());

  ct.onDeal(deal);

  // utilities are u1=10, u2=0
  double u1 = 10.0;
  double u2 = 0.0;
  double sum_e = exp(u1)+exp(u2);
  double sum_ue = u1*exp(u1)+u2*exp(u2);
  double deriv = exp(u1)*(u1*sum_e - sum_ue)/(sum_e*sum_e);

  d = deal.getProfitDerivative(1.0);
  ASSERT_EQUAL(d,deriv*deal.getNominalProfit());

  // mean_profit = (10+1)/2
  // dd = 0
  // u = 5.5
  ASSERT_EQUAL(ct.getUtility(),5.5);
  
  deal = new nvDeal();
  deal.open(ct2,ORDER_TYPE_BUY,1.23456,(int)time-3600*4,0.5);
  deal.close(1.23457,time-3600*2,8.0);
  deal.setMarketType(ct.getMarketType());
  ct2.onDeal(deal);

  ASSERT_EQUAL(ct2.getUtility(),8.0);

  deal = new nvDeal();
  deal.open(ct2,ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
  deal.close(1.23457,time-3600,1.0);
  deal.setMarketType(ct.getMarketType());
  ct2.onDeal(deal);

  // utilities are u1=5.5, u2=8
  u1 = 5.5;
  u2 = 8.0;
  sum_e = exp(u1)+exp(u2);
  sum_ue = u1*exp(u1)+u2*exp(u2);
  deriv = exp(u2)*(u2*sum_e - sum_ue)/(sum_e*sum_e);

  d = deal.getProfitDerivative(1.0);
  ASSERT_EQUAL(d,deriv*deal.getNominalProfit());

  // Reset the portfolio manager:
  man.reset(); 
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
