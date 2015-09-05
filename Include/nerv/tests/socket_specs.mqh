
#include <nerv/unit/Testing.mqh>
#include <nerv/network/Socket.mqh>

BEGIN_TEST_PACKAGE(socket_specs)

BEGIN_TEST_SUITE("Socket class")

BEGIN_TEST_CASE("should be able to create a socket instance")
	nvSocket socket;
	ASSERT_VALID_PTR(socket);
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

END_TEST_SUITE()

END_TEST_PACKAGE()
