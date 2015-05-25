// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/tests/sanity_specs.mqh>
#include <nerv/tests/math_specs.mqh>
#include <nerv/tests/map_specs.mqh>
#include <nerv/tests/TradeModel_specs.mqh>
#include <nerv/tests/RRLModel_specs.mqh>
#include <nerv/tests/HistoryMap_specs.mqh>
#include <nerv/tests/Strategy_specs.mqh>
#include <nerv/tests/RRLCostfunc_SR_specs.mqh>
#include <nerv/tests/StrategyEvaluator_specs.mqh>

BEGIN_TEST_SESSION("RRL_Results")

// Then retrieve the log file and ensure we find the entry we just wrote.
nvLogManager* lm = nvLogManager::instance();
string fname = "test_trade.log";
nvFileLogger* logger = new nvFileLogger(fname);
lm.addSink(logger);


// LOAD_TEST_PACKAGE(sanity_specs)
// LOAD_TEST_PACKAGE(math_specs)
// LOAD_TEST_PACKAGE(map_specs)
// LOAD_TEST_PACKAGE(trademodel_specs)
// LOAD_TEST_PACKAGE(rrlmodel_specs)
// LOAD_TEST_PACKAGE(historymap_specs)
// LOAD_TEST_PACKAGE(strategy_specs)
// LOAD_TEST_PACKAGE(costfunc_SR_specs)
LOAD_TEST_PACKAGE(strategyevaluator_specs)

END_TEST_SESSION()
