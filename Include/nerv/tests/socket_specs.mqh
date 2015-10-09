
#include <nerv/unit/Testing.mqh>
#include <nerv/network/Socket.mqh>

BEGIN_TEST_PACKAGE(socket_specs)

BEGIN_TEST_SUITE("Socket class")

BEGIN_TEST_CASE("should be able to create a socket instance")
	// Should throw an error if lib is not initialized yet:
	BEGIN_ASSERT_ERROR("Winsock not initialized.")
  { nvSocket socket;
		// ASSERT_VALID_PTR(socket); 
	}
	END_ASSERT_ERROR();

	// Should create properly once initialized:
	nvSocket::initialize();
	{
		nvSocket socket;	
	}
	nvSocket::uninitialize();
END_TEST_CASE()

BEGIN_TEST_CASE("Should support WSA init/unit")
  bool res = nvSocket::initialize();
  ASSERT_EQUAL(res,true);
  nvSocket::uninitialize();
END_TEST_CASE()

BEGIN_TEST_CASE("Should support multiple calls to init/uninit")
  bool res = nvSocket::initialize();
  ASSERT_EQUAL(res,true);
  res = nvSocket::initialize();
  ASSERT_EQUAL(res,true);
  res = nvSocket::initialize();
  ASSERT_EQUAL(res,true);
  nvSocket::uninitialize();
  nvSocket::uninitialize();
  nvSocket::uninitialize();  
END_TEST_CASE()

BEGIN_TEST_CASE("Should not be able to connect to invalid server")
  nvSocket::initialize();
  {
	  nvSocket socket;
	  bool res = socket.connect("127.0.0.1",10000);
	  ASSERT_EQUAL(res,false);  	
  }
  nvSocket::uninitialize();
END_TEST_CASE()

BEGIN_TEST_CASE("Should connect to external server")
  nvSocket::initialize();
  {
	  nvSocket socket;
	  bool res = socket.connect("127.0.0.1",22220);
	  ASSERT_EQUAL(res,true);

	  // Send a socket message:
	  socket.send("Hello manu!");
	  
  }
  nvSocket::uninitialize();
END_TEST_CASE()

XBEGIN_TEST_CASE("Establish a connection with a server socket")
  nvSocket::initialize();
  {
	  nvSocket server;
	  logDEBUG("Calling server:bind()")
	  bool res = server.bind(10000);
	  ASSERT_EQUAL(res,true);

	  logDEBUG("Calling server:listen()")
	  res = server.listen(3);
	  ASSERT_EQUAL(res,true);

	  // Now create the client:
	  logDEBUG("Calling client:connect()")
	  nvSocket client;
	  res = client.connect("127.0.0.1",10000);
	  ASSERT_EQUAL(res,true);
  }
  nvSocket::uninitialize();
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
