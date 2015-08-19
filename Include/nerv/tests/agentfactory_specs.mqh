
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/AgentFactory.mqh>

BEGIN_TEST_PACKAGE(agentfactory_specs)

BEGIN_TEST_SUITE("AgentFactory class")

BEGIN_TEST_CASE("should be able to retrieve AgentFactoy instance")
	nvPortfolioManager man;
	nvAgentFactory* factory = man.getAgentFactory();
	ASSERT_NOT_NULL(factory);
END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()
