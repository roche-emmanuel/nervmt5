// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/tests/sanity_specs.mqh>
#include <nerv/tests/expert_specs.mqh>
#include <nerv/tests/portfoliomanager_specs.mqh>
#include <nerv/tests/currencytrader_specs.mqh>

BEGIN_TEST_SESSION("Expert_Results")

LOAD_TEST_PACKAGE(sanity_specs)
LOAD_TEST_PACKAGE(expert_specs)
LOAD_TEST_PACKAGE(portfoliomanager_specs)
LOAD_TEST_PACKAGE(currencytrader_specs)

END_TEST_SESSION()
