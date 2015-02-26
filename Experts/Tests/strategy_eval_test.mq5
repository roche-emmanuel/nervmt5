// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/tests/strategy_eval_specs.mqh>

BEGIN_TEST_SESSION("RRL_Results")

// Then retrieve the log file and ensure we find the entry we just wrote.
nvLogManager* lm = nvLogManager::instance();
string fname = "test_strategy_eval.log";
nvFileLogger* logger = new nvFileLogger(fname);
lm.addSink(logger);

LOAD_TEST_PACKAGE(strategy_eval_specs)

END_TEST_SESSION()
