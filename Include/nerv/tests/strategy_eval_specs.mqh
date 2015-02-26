
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trades.mqh>
#include <nerv/trade/Strategy.mqh>
#include <nerv/trade/rrl/RRLModel.mqh>

BEGIN_TEST_PACKAGE(strategy_eval_specs)

BEGIN_TEST_SUITE("Strategy evaluation")

BEGIN_TEST_CASE("should support evaluation of strategy")
  string symbol = "EURUSD";
  ENUM_TIMEFRAMES period = PERIOD_M1;
  // int offset = 0;
  datetime starttime = D'21.02.2015 12:00:00';
  // logDEBUG("Current time GMT: "<<TimeGMT());
  // logDEBUG("Current time Local: "<<TimeLocal());

  int count = 100000;

  double arr[];
  // int res = CopyClose(symbol, period, offset, count, arr);
  int res = CopyClose(symbol, period, starttime, count, arr);
  REQUIRE_EQUAL(res,count);

  // build a vector from the prices:
  nvVecd all_prices(arr);

  nvVecd final_wealth;
  
  int tsize = 20000;
  int step = 500;
  int numit = 1+(count - tsize)/step;
  logDEBUG("Number of iterations: "<<numit);

  int poffset = 0;
  for(int i=0;i<numit;++i)
  {
    // Generate a price serie:
    poffset = i*step;
    
    logDEBUG("Testing from offset: "<<poffset);
    MESSAGE("Performing iteration "<<i<<"...");
    Sleep(10);

    nvVecd prices = all_prices.subvec(poffset,tsize);

    nvStrategy st(symbol,period);  

    // Assign a model to the strategy:
    nvRRLModelTraits traits;
    
    // Keep history:
    traits.historyLength(0);

    // Do not write history data to disk.
    traits.autoWriteHistory(false); 

    traits.id("test1_eur");
    st.setModel(new nvRRLModel(traits));

    st.dryrun(prices);

    // Now retrieve the wealth data:
    nvVecd* wealth = (nvVecd*)st.getModel().getHistoryMap().get("wealth");
    REQUIRE_VALID_PTR(wealth);
    double fw = wealth.back();
    logDEBUG("Acheived final wealth: "<<fw);
    final_wealth.push_back(fw);
  }

  logDEBUG("Wealth mean: "<< final_wealth.mean());
  logDEBUG("Wealth deviation: "<< final_wealth.deviation());
  final_wealth.writeTo("final_wealth.txt");

END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
