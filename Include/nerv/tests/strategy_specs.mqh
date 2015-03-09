
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trade/Strategy.mqh>
#include <nerv/trade/rrl/RRLModel.mqh>

BEGIN_TEST_PACKAGE(strategy_specs)

BEGIN_TEST_SUITE("Strategy class")

BEGIN_TEST_CASE("should be able to create a strategy object")
	nvStrategyTraits traits;
  nvStrategy* st = new nvStrategy(traits);  
  REQUIRE(st!=NULL);
  delete st;
END_TEST_CASE()

BEGIN_TEST_CASE("should support dryrun")
	nvStrategyTraits straits;
  nvStrategy st(straits);  

  // Assign a model to the strategy:
  nvRRLModelTraits traits;
  
  // Keep history:
  traits.historyLength(0);

  // Do not write history data to disk.
  traits.autoWriteHistory(false); 

  traits.id("test_");
  st.setModel(new nvRRLModel(traits));

  int size = 100;
  nvVecd prices(size);
  for(int i=0; i<size; ++i)
  {
    prices.set(i,i+1); // The clsoe price should never be 0.0
  }
  //prices.randomize(1.1,1.4);

  st.dryrun(prices);

  // This should have generated a few result vectors
  // That we can retrieve from the model history.
  nvHistoryMap* history = st.getModel().getHistoryMap();

  REQUIRE_GE(history.size(),4);

  nvVecd* gen_prices = (nvVecd*)history.get("close_prices");
  REQUIRE_VALID_PTR(gen_prices);
  REQUIRE_EQUAL(gen_prices.size(),size-1);
  REQUIRE_EQUAL(gen_prices[0],2);
  REQUIRE_EQUAL(gen_prices[size-2],size);

  // Also check the return prices:
  nvVecd* gen_returns = (nvVecd*)history.get("price_returns");
  REQUIRE_VALID_PTR(gen_returns);
  nvVecd rets(size-1,1.0);
  REQUIRE_EQUAL(gen_returns,rets);
END_TEST_CASE()

XBEGIN_TEST_CASE("should support dryrun with a real price serie")
  nvVecd prices("eur_prices.txt");
  REQUIRE_EQUAL(prices.size(),7123);

  {
  	nvStrategyTraits straits;
  	nvStrategy st(straits); 
  
    // Assign a model to the strategy:
    nvRRLModelTraits traits;
    
    // Keep history:
    traits.historyLength(0);

    // Do not write history data to disk.
    traits.autoWriteHistory(true); 

    traits.id("test1_eur");
    st.setModel(new nvRRLModel(traits));

    st.dryrun(prices);    
  }

  // Should have written the result files:
  nvVecd gen_prices("test1_eur_close_prices.txt");
  REQUIRE_EQUAL(gen_prices.size(),7122);
  REQUIRE_EQUAL(gen_prices[0],prices[1]);
END_TEST_CASE()

BEGIN_TEST_CASE("should support dryrun with generated price serie")
  nvStrategyTraits straits;
 	straits.symbol("EURUSD").period(PERIOD_M1);
  straits.historyLength(0);
  straits.autoWriteHistory(false);
  straits.id("test1_eur");
  straits.warmUpLength(0);
  straits.signalThreshold(0.0);
  
  //double tcost = 0.00001;
  double tcost = 0.00300;

  straits.transactionCost(tcost);

  // Assign a model to the strategy:
  nvRRLModelTraits traits;
  traits.transactionCost(tcost);  
  traits.batchTrainLength(500);
  // traits.batchTrainLength(1000);
  traits.batchTrainFrequency(200);
  traits.onlineTrainLength(-1);
  traits.lambda(0.0);
  traits.trainMode(TRAIN_STOCHASTIC_GRADIENT_DESCENT);
  traits.trainAlgorithm(TRAIN_SR);
  traits.warmInit(true);
  traits.numEpochs(15);
  traits.learningRate(0.01);

  // Keep history:
  traits.historyLength(0);
  // Do not write history data to disk.
  traits.autoWriteHistory(false); 
  traits.id("test1_eur");
  traits.numInputReturns(10);

  datetime starttime = D'21.02.2015 12:00:00';

  int offset = 80000;
  int count = 900;

  // double arr[];
  // int res = CopyClose(straits.symbol(), straits.period(), starttime, count, arr);
  // REQUIRE_EQUAL(res,count);

  // build a vector from the prices:
  // nvVecd prices(arr);

  nvVecd prices = nv_generatePrices(count, 0.9, 3.0, 0.5, 1.2);


  nvVecd rets = prices.subvec(1,prices.size()-1) - prices.subvec(0,prices.size()-1);
  logDEBUG("Global returns mean: "<<rets.mean()<<", dev:"<<rets.deviation());
  
  traits.fixReturnsMeanDev(rets.mean(),rets.deviation());

  {
  	nvStrategy st(straits); 

    st.setModel(new nvRRLModel(traits));

    st.dryrun(prices);    
  }
END_TEST_CASE()


BEGIN_TEST_CASE("Should provide constant results with default SR cost")
  
  int count = 900;
  nvVecd prices = nv_generatePrices(count, 0.9, 3.0, 1.125, 1.15);
  nvVecd rets = nv_generate_returns(prices);

  nvStrategyTraits straits;
  straits.historyLength(0);

  nvRRLModelTraits mtraits;
  mtraits.historyLength(0);

  double tcost = 0.000001;
  straits.transactionCost(tcost);
  
  mtraits.transactionCost(tcost);  
  mtraits.batchTrainLength(500);
  mtraits.batchTrainFrequency(200);
  mtraits.onlineTrainLength(-1);

  mtraits.trainMode(TRAIN_STOCHASTIC_GRADIENT_DESCENT);
  mtraits.warmInit(true);
  mtraits.fixReturnsMeanDev(rets.mean(),rets.deviation());

  {
    nvStrategy st(straits); 

    st.setModel(new nvRRLModel(mtraits));

    st.dryrun(prices);    

    nvVecd* wealth = (nvVecd*)st.getHistoryMap().get("strategy_wealth");
    nvVecd* ndeals = (nvVecd*)st.getHistoryMap().get("strategy_num_deals");

    double w = wealth.back();
    double dd = computeMaxDrawnDown(wealth);
    double nd = ndeals.back();
    // MESSAGE("Final wealth: "<<w<<", dd: "<<dd<<", nd: "<<nd);

    REQUIRE_CLOSE(w,0.03752210414999378,1e-10);
    REQUIRE_CLOSE(dd,0.002940529703623393,1e-10);
    REQUIRE_EQUAL(nd,398);
  }
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide constant results on secondary test")
  
  int count = 900;
  nvVecd prices = nv_generatePrices(count, 0.9, 3.0, 1.125, 1.15);
  nvVecd rets = nv_generate_returns(prices);

  nvStrategyTraits straits;
  straits.historyLength(0);

  nvRRLModelTraits mtraits;
  mtraits.historyLength(0);

  double tcost = 0.000001;
  straits.transactionCost(tcost);
  
  mtraits.transactionCost(tcost);  
  mtraits.batchTrainLength(500);
  mtraits.batchTrainFrequency(200);
  mtraits.onlineTrainLength(-1);

  mtraits.trainMode(TRAIN_STOCHASTIC_GRADIENT_DESCENT);
  mtraits.warmInit(true);
  mtraits.fixReturnsMeanDev(rets.mean(),rets.deviation());

  {
    nvStrategy st(straits); 

    st.setModel(new nvRRLModel(mtraits));

    st.dryrun(prices);    

    nvVecd* wealth = (nvVecd*)st.getHistoryMap().get("strategy_wealth");
    nvVecd* ndeals = (nvVecd*)st.getHistoryMap().get("strategy_num_deals");

    double w = wealth.back();
    double dd = computeMaxDrawnDown(wealth);
    double nd = ndeals.back();
    // MESSAGE("Final wealth: "<<w<<", dd: "<<dd<<", nd: "<<nd);

    REQUIRE_CLOSE(w,0.03752210414999378,1e-10);
    REQUIRE_CLOSE(dd,0.002940529703623393,1e-10);
    REQUIRE_EQUAL(nd,398);
  }
END_TEST_CASE()


BEGIN_TEST_CASE("Should provide constant results with SR cost and exact gradient descent")
  
  int count = 900;
  nvVecd prices = nv_generatePrices(count, 0.9, 3.0, 1.125, 1.15);
  nvVecd rets = nv_generate_returns(prices);

  nvStrategyTraits straits;
  straits.historyLength(0);

  nvRRLModelTraits mtraits;
  mtraits.historyLength(0);

  double tcost = 0.000001;
  straits.transactionCost(tcost);
  
  mtraits.transactionCost(tcost);  
  mtraits.batchTrainLength(500);
  mtraits.batchTrainFrequency(200);
  mtraits.onlineTrainLength(-1);
  mtraits.learningRate(50.0);
  mtraits.numEpochs(30);

  mtraits.trainMode(TRAIN_BATCH_GRADIENT_DESCENT);
  mtraits.warmInit(true);
  mtraits.fixReturnsMeanDev(rets.mean(),rets.deviation());

  {
    nvStrategy st(straits); 

    st.setModel(new nvRRLModel(mtraits));

    st.dryrun(prices);    

    nvVecd* wealth = (nvVecd*)st.getHistoryMap().get("strategy_wealth");
    nvVecd* ndeals = (nvVecd*)st.getHistoryMap().get("strategy_num_deals");

    double w = wealth.back();
    double dd = computeMaxDrawnDown(wealth);
    double nd = ndeals.back();
    // MESSAGE("Final wealth: "<<w<<", dd: "<<dd<<", nd: "<<nd);

    REQUIRE_CLOSE(w,0.0367976299433898,1e-10);
    REQUIRE_CLOSE(dd,0.003756371506408446,1e-10);
    REQUIRE_EQUAL(nd,390);
  }
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
