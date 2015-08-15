
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/UtilityEfficiencyOptimizer.mqh>

BEGIN_TEST_PACKAGE(utilityefficiencyoptimizer_specs)

BEGIN_TEST_SUITE("UtilityEfficiencyOptimizer class")

BEGIN_TEST_CASE("should be able to create an instance of the class")
	nvUtilityEfficiencyOptimizer opt;
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
