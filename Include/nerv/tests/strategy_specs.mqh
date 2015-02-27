
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

BEGIN_TEST_CASE("should support dryrun with price serie from MT5")
  nvStrategyTraits straits;
 	straits.symbol("EURUSD").period(PERIOD_M1);
  straits.historyLength(0);
  straits.autoWriteHistory(true);
  straits.id("test1_eur");
  straits.warmUpLength(3000);
  
  int offset = 80000;
  int count = 20000;

  double arr[];
  int res = CopyClose(straits.symbol(), straits.period(), offset, count, arr);
  REQUIRE_EQUAL(res,count);

  // build a vector from the prices:
  nvVecd prices(arr);

  {
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
END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()
