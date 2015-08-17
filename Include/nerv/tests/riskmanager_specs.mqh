
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/RiskManager.mqh>

BEGIN_TEST_PACKAGE(riskmanager_specs)

BEGIN_TEST_SUITE("RiskManager class")

BEGIN_TEST_CASE("should be able to create a RiskManager instance")
	nvRiskManager rman;
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
