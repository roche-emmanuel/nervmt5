
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trades.mqh>
#include <nerv/trade/Strategy.mqh>
#include <nerv/trade/rrl/RRLModel.mqh>

struct StrategyEvalConfig
{
  nvStrategyTraits straits;
  nvRRLModelTraits mtraits;

  nvVecd prices;
  nvVecd st_final_wealth;
  nvVecd st_max_dd;
  nvVecd st_num_deals;  

  ulong duration;
};

void evaluate_strategy(StrategyEvalConfig& cfg)
{
  nvStrategy st(cfg.straits);

  st.setModel(new nvRRLModel(cfg.mtraits));

  st.dryrun(cfg.prices);

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
    CHECK_PTR(wealth,"Invalid pointer");
    double fw = wealth.back();
    logDEBUG("Acheived St. final wealth: "<<fw);
    cfg.st_final_wealth.push_back(fw);

    // Compute the max drawndown of this run:
    double dd = computeMaxDrawnDown(wealth);
    logDEBUG("Acheived St. max drawdown "<<dd);
    cfg.st_max_dd.push_back(dd);
  }

  {
    // Retrieve the number of deals performed:
    nvVecd* ndeals = (nvVecd*)st.getHistoryMap().get("strategy_num_deals");
    CHECK_PTR(ndeals,"Invalid pointer");
    double nd = ndeals.back();
    logDEBUG("Acheived St. num deals: "<<nd);
    cfg.st_num_deals.push_back(nd);      
  }
}

void report_evaluation_results(StrategyEvalConfig& cfg)
{
  // logDEBUG("Th. Wealth mean: "<< final_wealth.mean());
  // logDEBUG("Th. Wealth deviation: "<< final_wealth.deviation());
  // // final_wealth.writeTo("final_wealth.txt");

  // logDEBUG("Th. Max DrawDown mean: "<< max_dd.mean());
  // logDEBUG("Th. Max DrawDown deviation: "<< max_dd.deviation());
  // // max_dd.writeTo("max_drawdown.txt");
  nvStringStream os;
  os << "St. Wealth mean: "<< cfg.st_final_wealth.mean() << "\n";
  os << "St. Wealth deviation: "<< cfg.st_final_wealth.deviation() << "\n";
  cfg.st_final_wealth.writeTo("test_final_wealth.txt");

  os << "St. Max DrawDown mean: "<< cfg.st_max_dd.mean() <<"\n";
  os << "St. Max DrawDown deviation: "<< cfg.st_max_dd.deviation() << "\n";
  cfg.st_max_dd.writeTo("test_max_drawdown.txt");

  os << "St. Num deals mean: "<< cfg.st_num_deals.mean() << "\n";
  os << "St. Num deals deviation: "<< cfg.st_num_deals.deviation() << "\n";
  cfg.st_num_deals.writeTo("test_num_deals.txt");

  os << "\n";
  
  os << "Evaluation duration: " << formatTime(cfg.duration) << "\n";

  logDEBUG(os.str());
	
	bool res = SendMail("[MT5] - Strategy evaluation results",os.str());
	
  CHECK(res,"Cannot send mail.");
}

BEGIN_TEST_PACKAGE(strategy_eval_specs)

BEGIN_TEST_SUITE("Strategy evaluation")

BEGIN_TEST_CASE("should support evaluation of strategy")

  StrategyEvalConfig cfg;

 	cfg.straits.symbol("EURUSD").period(PERIOD_M1);
  cfg.straits.historyLength(0);
  cfg.straits.autoWriteHistory(false); 
  cfg.straits.id("test1_eur");
	
  // Keep history:
  cfg.mtraits.historyLength(0);
  // Do not write history data to disk.
  cfg.mtraits.autoWriteHistory(false); 
  cfg.mtraits.id("test1_eur");

  // Settings:
  double tcost = 0.000001;
  cfg.straits.warmUpLength(0);
  cfg.straits.signalThreshold(0.0);
  cfg.straits.signalAdaptation(0.01); // This as no effect for now => Signal EMA not used.
  cfg.straits.signalMeanLength(100);
  cfg.straits.transactionCost(tcost);
  
  cfg.mtraits.transactionCost(tcost);  
  cfg.mtraits.batchTrainLength(2000);
  cfg.mtraits.batchTrainFrequency(500);
  cfg.mtraits.onlineTrainLength(-1);
  cfg.mtraits.lambda(0.0);
  cfg.mtraits.numInputReturns(10);
  cfg.mtraits.maxIterations(30);

  cfg.mtraits.trainMode(TRAIN_STOCHASTIC_GRADIENT_DESCENT);
  cfg.mtraits.warmInit(true);
  cfg.mtraits.numEpochs(15);
  cfg.mtraits.learningRate(0.01);

  // int offset = 0;
  datetime start = D'21.02.2015 12:00:00';
  // logDEBUG("Current time GMT: "<<TimeGMT());
  // logDEBUG("Current time Local: "<<TimeLocal());

  int count = 100000;
  //int count = 21000;

  double arr[];
  // int res = CopyClose(symbol, period, offset, count, arr);
  int res = CopyClose(cfg.straits.symbol(), cfg.straits.period(), start, count, arr);
  REQUIRE_EQUAL(res,count);

  // build a vector from the prices:
  nvVecd all_prices(arr);

  nvVecd rets = all_prices.subvec(1,all_prices.size()-1) - all_prices.subvec(0,all_prices.size()-1);
  logDEBUG("Global returns mean: "<<rets.mean()<<", dev:"<<rets.deviation());
  
  cfg.mtraits.fixReturnsMeanDev(rets.mean(),rets.deviation());

  int tsize = 20000;
  int step = 500;
  int numit = 1+(count - tsize)/step;
  logDEBUG("Number of iterations: "<<numit);

  datetime startTime = TimeLocal();
  logDEBUG("Evaluation started at "<<startTime);

  int poffset = 0;
  for(int i=0;i<numit;++i)
  {
    // Generate a price serie:
    poffset = i*step;
    
    logDEBUG("Testing from offset: "<<poffset);
    MESSAGE("Performing iteration "<<i<<"...");
    Sleep(10);

    cfg.prices = all_prices.subvec(poffset,tsize);

    evaluate_strategy(cfg);

    datetime tick = TimeLocal();
    ulong elapsed = tick - startTime;
    ulong meanDuration = (ulong) ((double)elapsed / (double)(i+1));
    datetime completionAt = (datetime)(startTime + meanDuration * (ulong)numit);
    ulong left = completionAt - tick;

    // convert the number of seconds left to hours/min/secs:
    string timeLeft = formatTime(left);

    MESSAGE("Mean duration: "<<meanDuration<<" seconds. Completion at :"<<completionAt<<" ("<<timeLeft<<" left)");
  }

  cfg.duration = TimeLocal() - startTime;
  report_evaluation_results(cfg);
END_TEST_CASE()

BEGIN_TEST_CASE("should support computing long term profit")
  nvStrategyTraits straits;
  straits.symbol("EURUSD").period(PERIOD_M1);
  straits.historyLength(0);
  straits.autoWriteHistory(false); 
  straits.id("test1_eur");
  
  // Prepare the model traits:
  nvRRLModelTraits mtraits;

  // Keep history:
  mtraits.historyLength(0);
  // Do not write history data to disk.
  mtraits.autoWriteHistory(false); 
  mtraits.id("test1_eur");

  // Settings:
  double tcost = 0.000001;
  straits.warmUpLength(0);
  straits.signalThreshold(0.0);
  straits.signalAdaptation(0.01); // This as no effect for now => Signal EMA not used.
  straits.signalMeanLength(100);
  straits.transactionCost(tcost);
  
  mtraits.transactionCost(tcost);  
  mtraits.batchTrainLength(2000);
  mtraits.batchTrainFrequency(500);
  mtraits.onlineTrainLength(-1);
  mtraits.lambda(0.0);
  mtraits.numInputReturns(10);
  mtraits.maxIterations(30);

  mtraits.trainMode(TRAIN_STOCHASTIC_GRADIENT_DESCENT);
  mtraits.warmInit(true);
  mtraits.numEpochs(15);
  mtraits.learningRate(0.01);

  // int offset = 0;
  datetime starttime = D'21.10.2014 12:00:00';
  // logDEBUG("Current time GMT: "<<TimeGMT());
  // logDEBUG("Current time Local: "<<TimeLocal());

  int count = 100000;

  double arr[];
  // int res = CopyClose(symbol, period, offset, count, arr);
  int res = CopyClose(straits.symbol(), straits.period(), starttime, count, arr);
  REQUIRE_EQUAL(res,count);

  // build a vector from the prices:
  nvVecd all_prices(arr);

  nvVecd rets = all_prices.subvec(1,all_prices.size()-1) - all_prices.subvec(0,all_prices.size()-1);
  logDEBUG("Global returns mean: "<<rets.mean()<<", dev:"<<rets.deviation());
  
  mtraits.fixReturnsMeanDev(rets.mean(),rets.deviation());

  nvVecd prices = all_prices;

  nvStrategy st(straits);

  st.setModel(new nvRRLModel(mtraits));

  st.dryrun(prices);

  {
    // Now retrieve the wealth data from the strategy itself:
    nvVecd* wealth = (nvVecd*)st.getHistoryMap().get("strategy_wealth");
    REQUIRE_VALID_PTR(wealth);
    double fw = wealth.back();
    logDEBUG("Long St. final wealth: "<<fw);
    wealth.writeTo("test_long_strategy_wealth.txt");

    // Compute the max drawndown of this run:
    double dd = computeMaxDrawnDown(wealth);
    logDEBUG("Long St. max drawdown "<<dd);
  }

  {
    // Retrieve the number of deals performed:
    nvVecd* ndeals = (nvVecd*)st.getHistoryMap().get("strategy_num_deals");
    REQUIRE_VALID_PTR(ndeals);
    double nd = ndeals.back();
    logDEBUG("Long St. num deals: "<<nd);
  }

  all_prices.writeTo("test_long_strategy_prices.txt");

END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
