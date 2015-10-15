
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/PortfolioManager.mqh>

BEGIN_TEST_PACKAGE(pricemanager_specs)

BEGIN_TEST_SUITE("PriceManager class")

BEGIN_TEST_CASE("should be available in portfolio manager")
  nvPortfolioManager man;
  nvPriceManager* pman = man.getPriceManager();
  ASSERT_NOT_NULL(pman);
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide bid/ask price at any time")
  nvPortfolioManager man;
  nvPriceManager* pman = man.getPriceManager();

  int num = 30;
  datetime time = TimeCurrent();
  int range = 3600*24*7; // range of 7 days.
  SimpleRNG rng;
  rng.SetSeedFromSystemTime();

  MqlRates rates[];

  string symbol = "EURUSD";

  for(int i = 0;i<num;++i)
  {
    // compute a time point:
    datetime ctime = time - rng.GetInt(1,range);
    double bid = pman.getBidPrice(symbol,ctime);
    double ask = pman.getAskPrice(symbol,ctime);

    // Compare with that minute data:
    ASSERT_EQUAL(CopyRates(symbol,PERIOD_M1,ctime,1,rates),1);

    ASSERT_LE(bid,rates[0].high);
    ASSERT_GE(bid,rates[0].low);
    ASSERT_EQUAL(ask,bid+rates[0].spread*nvGetPointSize(symbol));
  }
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide bid/ask price at current server time")
  nvPortfolioManager man;
  nvPriceManager* pman = man.getPriceManager();

  datetime time = TimeCurrent();
  man.setCurrentTime(time);

  string symbol = "EURUSD";

  double bid = pman.getBidPrice(symbol);
  double ask = pman.getAskPrice(symbol);

  MqlTick last_tick;
  ASSERT(SymbolInfoTick(symbol,last_tick));

  ASSERT_LE(bid,last_tick.bid);
  ASSERT_LE(ask,last_tick.ask);
END_TEST_CASE()

BEGIN_TEST_CASE("Should support converting prices at any time")
  nvPortfolioManager man;
  nvPriceManager* pman = man.getPriceManager();

  int num = 30;
  datetime time = TimeCurrent();
  int range = 3600*24*7; // range of 7 days.
  SimpleRNG rng;
  rng.SetSeedFromSystemTime();

  MqlRates rates[];

  string symbol1 = "EURUSD";
  string symbol2 = "GBPJPY";
  double price = 1.23456;

  for(int i = 0;i<num;++i)
  {
    // compute a time point:
    datetime ctime = time - rng.GetInt(1,range);
    man.setCurrentTime(ctime);

    double p1 = pman.convertPrice(price,"EUR","USD");
    double p2 = pman.convertPrice(price,"JPY","GBP");

    // Retrieve the rate at that time:
    ASSERT_EQUAL(CopyRates(symbol1,PERIOD_M1,ctime,1,rates),1);

    double bid = (rates[0].high+rates[0].low+rates[0].close)/3.0;

    ASSERT_EQUAL(p1,price*bid);

    ASSERT_EQUAL(CopyRates(symbol2,PERIOD_M1,ctime,1,rates),1);
    bid = (rates[0].high+rates[0].low+rates[0].close)/3.0;
    double ask = (bid+rates[0].spread*nvGetPointSize(symbol2));
    ASSERT_EQUAL(p2,price/ask);
  }

END_TEST_CASE()

BEGIN_TEST_CASE("Should support converting prices at current server time")
  nvPortfolioManager man;
  nvPriceManager* pman = man.getPriceManager();

  datetime time = TimeCurrent();

  string symbol1 = "EURUSD";
  string symbol2 = "GBPJPY";
  double price = 1.23456;

  // compute a time point:
  man.setCurrentTime(time);

  double p1 = pman.convertPrice(price,"EUR","USD");
  double p2 = pman.convertPrice(price,"JPY","GBP");

  MqlTick last_tick;
  ASSERT(SymbolInfoTick(symbol1,last_tick));

  double bid = last_tick.bid;
  ASSERT_EQUAL(p1,price*bid);

  ASSERT(SymbolInfoTick(symbol2,last_tick));

  double ask = last_tick.ask;
  ASSERT_EQUAL(p2,price/ask);
END_TEST_CASE()

BEGIN_TEST_CASE("Should decrease value each time it is converted")
  nvPortfolioManager man;
  nvPriceManager* pman = man.getPriceManager();

  double p1 = 10000.0;
  double p2 = pman.convertPrice(p1,"EUR","USD");
  double p3 = pman.convertPrice(p2,"USD","EUR");
  double p4 = pman.convertPrice(p3,"EUR","USD");

  ASSERT_LT(p3,p1);
  ASSERT_LT(p4,p2);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to invert price conversions")
  nvPortfolioManager man;
  nvPriceManager* pman = man.getPriceManager();

  double p1 = 10000.0;
  double p2 = pman.convertPrice(p1,"EUR","USD");
  double p3 = pman.convertPriceInv(p2,"EUR","USD");

  ASSERT_EQUAL(p1,p3);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
