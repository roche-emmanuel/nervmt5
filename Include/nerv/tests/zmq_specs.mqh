
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
  // // Should throw an error if not initialized:
  // BEGIN_ASSERT_ERROR("ZMQ is not initialized.")
	 //  nvZMQSocket socket(ZMQ_PAIR);
  // END_ASSERT_ERROR();
  
  // // Now initialize properly:
  // nvZMQContext::instance().init();
  // {nvZMQSocket socket2(ZMQ_PAIR);}
  // nvZMQContext::instance().uninit();

  // Should in fact auto init the context if needed:
  nvZMQSocket socket2(ZMQ_PAIR);
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

BEGIN_TEST_CASE("Should be able to connect a socket")
  nvZMQSocket socket(ZMQ_PAIR);
  socket.connect("tcp://localhost:22222");
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to bind a socket")
  nvZMQSocket socket(ZMQ_PAIR);
  socket.bind("tcp://*:22222");
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to send/receive with simple commands")
  nvZMQSocket client(ZMQ_PUSH);
	client.connect("tcp://localhost:22222");  
  nvZMQSocket server(ZMQ_PULL);
  server.bind("tcp://*:22222");

  string msg1 = "Hello world!";
  char ch1[];
  StringToCharArray(msg1,ch1);
  client.simple_send(ch1);

  Sleep(10); // We add some sleep to ensure the underlying IO threads gets
  // the time to send the message.

  char ch[];
  server.simple_receive(ch,13);
  int len = ArraySize( ch );
  ASSERT_EQUAL(len,13);
  string msg2 = CharArrayToString(ch);
  ASSERT_EQUAL(msg1,msg2);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to send/receive with a message")
  nvZMQSocket client(ZMQ_PUSH);
  client.connect("tcp://localhost:22222");  
  nvZMQSocket server(ZMQ_PULL);
  server.bind("tcp://*:22222");

  string msg1 = "Hello world!";
  char ch1[];
  StringToCharArray(msg1,ch1);
  client.send(ch1);

  Sleep(10); // We add some sleep to ensure the underlying IO threads gets
  // the time to send the message.

  char ch[];
  server.receive(ch);
  int len = ArraySize( ch );
  ASSERT_EQUAL(len,13);
  string msg2 = CharArrayToString(ch);
  ASSERT_EQUAL(msg1,msg2);
END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()
