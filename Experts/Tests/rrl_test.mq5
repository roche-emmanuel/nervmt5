// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/tests/math_specs.mqh>
#include <nerv/tests/RRLCostFunction_specs.mqh>
#include <nerv/tests/RRLModel_specs.mqh>

BEGIN_TEST_SESSION("RRL_Results")

LOAD_TEST_PACKAGE(math_specs)
LOAD_TEST_PACKAGE(rrlcostfunction_specs)
LOAD_TEST_PACKAGE(rrlmodel_specs)

END_TEST_SESSION()
