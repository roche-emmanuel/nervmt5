
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trade/StrategyEvaluator.mqh>

BEGIN_TEST_PACKAGE(strategyevaluator_specs)

BEGIN_TEST_SUITE("StrategyEvaluator class")

BEGIN_TEST_CASE("should be able to generate report file")
	nvStrategyEvalConfig cfg;

	cfg.st_final_wealth.push_back(1.0);
	cfg.st_final_wealth.push_back(1.5);
	cfg.st_final_wealth.push_back(1.4);
	cfg.st_final_wealth.push_back(1.2);
	cfg.st_final_wealth.push_back(0.9);

	string fname = "tmp/test_results.html";
	nvStrategyEvaluator::generateResults(cfg,fname);

  REQUIRE(FileIsExist(fname));

	// Try reading the generated file:
	string content = nvReadFile(fname);
	int index = StringFind(content,"<html>");
	REQUIRE_GT(index,-1);
	
	nvOpenFile(fname);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
