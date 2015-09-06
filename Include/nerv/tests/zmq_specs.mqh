
#include <nerv/unit/Testing.mqh>
#include <nerv/network/ZMQContext.mqh>
#include <nerv/network/ZMQSocket.mqh>

BEGIN_TEST_PACKAGE(zmq_specs)

BEGIN_TEST_SUITE("ZMQContext class")

BEGIN_TEST_CASE("should be able to retrieve singleton")
	nvZMQContext* context = nvZMQContext::instance();
	ASSERT(context!=NULL);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to init/uninit")
	nvZMQContext* context = nvZMQContext::instance();
	context.init();
	context.init();
	context.uninit();
	context.uninit();
END_TEST_CASE()

END_TEST_SUITE()

BEGIN_TEST_SUITE("ZMQSocket class")

BEGIN_TEST_CASE("Should be able to create a new socket")
  // Should throw an error if not initialized:
  BEGIN_ASSERT_ERROR("ZMQ is not initialized.")
	  nvZMQSocket socket(ZMQ_PAIR);
  END_ASSERT_ERROR();
  
  // Now initialize properly:
  nvZMQContext::instance().init();
  {nvZMQSocket socket2(ZMQ_PAIR);}
  nvZMQContext::instance().uninit();
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to open/close a new socket")
  nvZMQContext::instance().init();
  {
	  nvZMQSocket socket(ZMQ_PAIR);
		socket.close();
		socket.open(ZMQ_PUB);
		socket.close();    	
  }
  nvZMQContext::instance().uninit();
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
