
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trade/Strategy.mqh>
#include <nerv/trade/rrl/RRLModel.mqh>

BEGIN_TEST_PACKAGE(strategy_specs)

BEGIN_TEST_SUITE("Strategy class")

BEGIN_TEST_CASE("should be able to create a strategy object")
  nvStrategy* st = new nvStrategy("EURUSD",PERIOD_M1);  
  REQUIRE(st!=NULL);
  delete st;
END_TEST_CASE()

BEGIN_TEST_CASE("should support dryrun")
  nvStrategy st("EURUSD",PERIOD_M1);  

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
    prices.set(i,i);
  }
  //prices.randomize(1.1,1.4);

  st.dryrun(prices);

  // This should have generated a few result vectors
  // That we can retrieve from the model history.
  nvHistoryMap* history = st.getModel().getHistoryMap();

  REQUIRE_GE(history.size(),4);

  nvVecd* gen_prices = (nvVecd*)history.get("close_prices");
  REQUIRE(IS_VALID_POINTER(gen_prices));
  REQUIRE_EQUAL(gen_prices.size(),size-1);
  REQUIRE_EQUAL(gen_prices[0],1);
  REQUIRE_EQUAL(gen_prices[size-2],size-1);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
