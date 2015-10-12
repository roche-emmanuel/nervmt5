// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/tests/sanity_specs.mqh>
#include <nerv/tests/utils_specs.mqh>
#include <nerv/tests/expert_specs.mqh>
#include <nerv/tests/portfoliomanager_specs.mqh>
#include <nerv/tests/currencytrader_specs.mqh>
#include <nerv/tests/deal_specs.mqh>
#include <nerv/tests/optimizer_specs.mqh>
#include <nerv/tests/utilityefficiencyoptimizer_specs.mqh>
#include <nerv/tests/math_specs.mqh>
#include <nerv/tests/tradingagent_specs.mqh>
#include <nerv/tests/riskmanager_specs.mqh>
#include <nerv/tests/decisioncomposer_specs.mqh>
#include <nerv/tests/agentfactory_specs.mqh>
#include <nerv/tests/simplerng_specs.mqh>
#include <nerv/tests/bootstrapper_specs.mqh>
#include <nerv/tests/decisioncomposerfactory_specs.mqh>
#include <nerv/tests/virtualmarket_specs.mqh>
#include <nerv/tests/realmarket_specs.mqh>
#include <nerv/tests/pricemanager_specs.mqh>
#include <nerv/tests/zmq_specs.mqh>
#include <nerv/tests/binstream_specs.mqh>
#include <nerv/tests/indicatorbase_specs.mqh>

BEGIN_TEST_SESSION("Expert_Results")

LOAD_TEST_PACKAGE(sanity_specs)
LOAD_TEST_PACKAGE(utils_specs)
LOAD_TEST_PACKAGE(expert_specs)
LOAD_TEST_PACKAGE(portfoliomanager_specs)
LOAD_TEST_PACKAGE(currencytrader_specs)
LOAD_TEST_PACKAGE(deal_specs)
LOAD_TEST_PACKAGE(optimizer_specs)
LOAD_TEST_PACKAGE(utilityefficiencyoptimizer_specs)
LOAD_TEST_PACKAGE(math_specs)
LOAD_TEST_PACKAGE(simplerng_specs)
LOAD_TEST_PACKAGE(bootstrapper_specs)
LOAD_TEST_PACKAGE(tradingagent_specs)
LOAD_TEST_PACKAGE(riskmanager_specs)
LOAD_TEST_PACKAGE(decisioncomposer_specs)
LOAD_TEST_PACKAGE(agentfactory_specs)
LOAD_TEST_PACKAGE(decisioncomposerfactory_specs)
LOAD_TEST_PACKAGE(virtualmarket_specs)
LOAD_TEST_PACKAGE(realmarket_specs)
LOAD_TEST_PACKAGE(pricemanager_specs)
LOAD_TEST_PACKAGE(zmq_specs)
LOAD_TEST_PACKAGE(binstream_specs)
LOAD_TEST_PACKAGE(indicatorbase_specs)

END_TEST_SESSION()
