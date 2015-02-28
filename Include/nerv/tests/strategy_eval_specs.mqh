
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trades.mqh>
#include <nerv/trade/Strategy.mqh>
#include <nerv/trade/rrl/RRLModel.mqh>

BEGIN_TEST_PACKAGE(strategy_eval_specs)

BEGIN_TEST_SUITE("Strategy evaluation")

BEGIN_TEST_CASE("should support evaluation of strategy")
  nvStrategyTraits straits;
 	straits.symbol("EURUSD").period(PERIOD_M15);
  straits.historyLength(0);
  straits.autoWriteHistory(false); 
  straits.id("test1_eur");
	straits.warmUpLength(3000);
	
  // Prepare the model traits:
  nvRRLModelTraits mtraits;
  // Keep history:
  mtraits.historyLength(0);
  // Do not write history data to disk.
  mtraits.autoWriteHistory(false); 
  mtraits.id("test1_eur");

  // int offset = 0;
  datetime starttime = D'21.02.2015 12:00:00';
  // logDEBUG("Current time GMT: "<<TimeGMT());
  // logDEBUG("Current time Local: "<<TimeLocal());

  int count = 100000;

  double arr[];
  // int res = CopyClose(symbol, period, offset, count, arr);
  int res = CopyClose(straits.symbol(), straits.period(), starttime, count, arr);
  REQUIRE_EQUAL(res,count);

  // build a vector from the prices:
  nvVecd all_prices(arr);

  // nvVecd final_wealth;
  // nvVecd max_dd;
  nvVecd st_final_wealth;
  nvVecd st_max_dd;
  
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

    nvStrategy st(straits);

    st.setModel(new nvRRLModel(mtraits));

    st.dryrun(prices);

    // {
    //   // Now retrieve the wealth data:
    //   nvVecd* wealth = (nvVecd*)st.getModel().getHistoryMap().get("theoretical_wealth");
    //   REQUIRE_VALID_PTR(wealth);
    //   double fw = wealth.back();
    //   logDEBUG("Acheived Th. final wealth: "<<fw);
    //   final_wealth.push_back(fw);

    //   // Compute the max drawndown of this run:
    //   double dd = computeMaxDrawnDown(wealth);
    //   logDEBUG("Acheived Th. max drawdown "<<dd);
    //   max_dd.push_back(dd);      
    // }

    {
      // Now retrieve the wealth data from the strategy itself:
      nvVecd* wealth = (nvVecd*)st.getHistoryMap().get("strategy_wealth");
      REQUIRE_VALID_PTR(wealth);
      double fw = wealth.back();
      logDEBUG("Acheived St. final wealth: "<<fw);
      st_final_wealth.push_back(fw);

      // Compute the max drawndown of this run:
      double dd = computeMaxDrawnDown(wealth);
      logDEBUG("Acheived St. max drawdown "<<dd);
      st_max_dd.push_back(dd);
    }
  }

  // logDEBUG("Th. Wealth mean: "<< final_wealth.mean());
  // logDEBUG("Th. Wealth deviation: "<< final_wealth.deviation());
  // // final_wealth.writeTo("final_wealth.txt");

  // logDEBUG("Th. Max DrawDown mean: "<< max_dd.mean());
  // logDEBUG("Th. Max DrawDown deviation: "<< max_dd.deviation());
  // // max_dd.writeTo("max_drawdown.txt");

  logDEBUG("St. Wealth mean: "<< st_final_wealth.mean());
  logDEBUG("St. Wealth deviation: "<< st_final_wealth.deviation());
  st_final_wealth.writeTo("final_wealth.txt");

  logDEBUG("St. Max DrawDown mean: "<< st_max_dd.mean());
  logDEBUG("St. Max DrawDown deviation: "<< st_max_dd.deviation());
  st_max_dd.writeTo("max_drawdown.txt");
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
