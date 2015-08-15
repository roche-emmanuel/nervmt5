
#include <nerv/unit/Testing.mqh>
#include <nerv/math/Optimizer.mqh>

BEGIN_TEST_PACKAGE(optimizer_specs)

BEGIN_TEST_SUITE("Optimizer class")

BEGIN_TEST_CASE("should be able to create an Optimizer instance")
	nvOptimizer opt;
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
