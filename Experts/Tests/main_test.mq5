// Copyright 2015, NervTech
// https://wiki.singularityworld.net

#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"
#property version   "1.00"

// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/tests/sanity_specs.mqh>
#include <nerv/tests/core_specs.mqh>
#include <nerv/tests/math_specs.mqh>

BEGIN_TEST_SESSION("TestResults")

LOAD_TEST_PACKAGE(sanity_specs)
LOAD_TEST_PACKAGE(core_specs)
LOAD_TEST_PACKAGE(math_specs)

END_TEST_SESSION()
