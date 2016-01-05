// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/tests/sanity_specs.mqh>
#include <nerv/tests/simplerng_specs.mqh>
#include <nerv/tests/zmq_specs.mqh>

BEGIN_TEST_SESSION("RNN_Results")

LOAD_TEST_PACKAGE(sanity_specs)
LOAD_TEST_PACKAGE(zmq_specs)

END_TEST_SESSION()
