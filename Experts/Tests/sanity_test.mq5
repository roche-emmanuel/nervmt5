// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/tests/core_specs.mqh>
#include <nerv/tests/core_object_specs.mqh>
#include <nerv/tests/sanity_specs.mqh>
#include <nerv/tests/sanity_ref_specs.mqh>

BEGIN_TEST_SESSION("Sanity_Results")

LOAD_TEST_PACKAGE(sanity_specs)
LOAD_TEST_PACKAGE(sanity_ref_specs)
LOAD_TEST_PACKAGE(core_specs)
LOAD_TEST_PACKAGE(core_object_specs)

END_TEST_SESSION()
