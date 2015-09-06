
#include <nerv/unit/Testing.mqh>
#include <nerv/network/ZMQContext.mqh>

BEGIN_TEST_PACKAGE(zmq_specs)

BEGIN_TEST_SUITE("ZMQContext class")

BEGIN_TEST_CASE("should be able to retrieve singleton")
	nvZMQContext* context = nvZMQContext::instance();
	ASSERT(context!=NULL);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
