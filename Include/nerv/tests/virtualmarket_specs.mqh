
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/VirtualMarket.mqh>

BEGIN_TEST_PACKAGE(virtualmarket_specs)

BEGIN_TEST_SUITE("VirtualMarket class")

BEGIN_TEST_CASE("should be able to create a VirtualMarket instance")
	nvVirtualMarket vmarket;
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide info on open position status")
  nvPortfolioManager man;
  nvMarket* market = man.getMarket(MARKET_TYPE_VIRTUAL);

  ASSERT_EQUAL((int)market.getMarketType(),(int)MARKET_TYPE_VIRTUAL);

  // No open position by default:
  ASSERT_EQUAL(market.hasOpenPosition("EURUSD"),false)
  man.reset();

END_TEST_CASE()

BEGIN_TEST_CASE("Should allow retrieving position type")
  // For the moment this will just throw an error:
  nvVirtualMarket market;
  ASSERT_EQUAL((int)market.getPositionType("EURUSD"),(int)POS_NONE);
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide the value of the balance")
  nvPortfolioManager man;
  nvVirtualMarket* market = (nvVirtualMarket*)man.getMarket(MARKET_TYPE_VIRTUAL);
  
  // Assign a balance value:
  market.setBalance(2001.0);

  double balance = market.getBalance("EUR");

  // Compare with the assigned balance value:
  ASSERT_EQUAL(balance,2001.0);
END_TEST_CASE()

BEGIN_TEST_CASE("Should have a valid initial balance")
  nvPortfolioManager man;
  nvMarket* market = man.getMarket(MARKET_TYPE_VIRTUAL); 
  ASSERT_GT(market.getBalance("EUR"),0);
END_TEST_CASE()

BEGIN_TEST_CASE("Should update the virtual balance in case of virtual deal")
  nvPortfolioManager man;
  nvVirtualMarket* market = (nvVirtualMarket*)man.getMarket(MARKET_TYPE_VIRTUAL); 
  
  // Initialize the balance:
  market.setBalance(3000.0);

  // prepare a currency trader:
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  ct.setMarketType(MARKET_TYPE_VIRTUAL);

  // Now generate the virtual deal:
  nvDeal* deal = new nvDeal();
  deal.setMarketType(MARKET_TYPE_VIRTUAL);

  datetime time = TimeCurrent();
  deal.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
  deal.close(1.23457,time,10.0);

  // Send the deal to the CurrencyTrader:
  ct.onDeal(deal);

  double newb = market.getBalance();
  ASSERT_EQUAL(newb, 2990.0);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
