
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

END_TEST_SUITE()

END_TEST_PACKAGE()
