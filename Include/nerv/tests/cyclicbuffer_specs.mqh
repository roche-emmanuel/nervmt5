
#include <nerv/unit/Testing.mqh>
#include <nerv/core/CyclicBuffer.mqh>

BEGIN_TEST_PACKAGE(cyclicbuffer_specs)

BEGIN_TEST_SUITE("CyclicBuffer class")

BEGIN_TEST_CASE("should be able to create a CyclicBuffer")
	nvCyclicBuffer buf(4);
  ASSERT_EQUAL(buf.isFilled(),false);
  buf.push_back(1);
  buf.push_back(2);
  buf.push_back(3);
  ASSERT_EQUAL(buf.isFilled(),false);
  buf.push_back(4);
  ASSERT_EQUAL(buf.isFilled(),true);
  ASSERT_EQUAL(buf.back(),4);
  ASSERT_EQUAL(buf.front(),1);
  buf.push_back(5);
  ASSERT_EQUAL(buf.back(),5);
  ASSERT_EQUAL(buf.front(),2);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
