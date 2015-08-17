
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/DecisionComposer.mqh>

BEGIN_TEST_PACKAGE(decisioncomposer_specs)

BEGIN_TEST_SUITE("DecisionComposer class")

BEGIN_TEST_CASE("should be able to create a DecisionComposer instance")
	nvPortfolioManager* man = nvPortfolioManager::instance();
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");

  nvDecisionComposer comp(ct);

  man.reset();
END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()
