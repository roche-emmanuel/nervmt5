
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/IndicatorBase.mqh>

BEGIN_TEST_PACKAGE(indicatorbase_specs)

BEGIN_TEST_SUITE("IndicatorBase class")

BEGIN_TEST_CASE("should be able to create an IndicatorBase instance")
	nvPortfolioManager man;
	nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
	
  nvIndicatorBase indicator(GetPointer(ct));
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
