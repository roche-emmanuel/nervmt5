
#include <nerv/unit/Testing.mqh>
#include <nerv/math.mqh>

BEGIN_TEST_PACKAGE(math_specs)

BEGIN_TEST_SUITE("Math components")

BEGIN_TEST_CASE("should be able to create a vector")
  int len = 10;
  nvVecd vec(len);
  REQUIRE_EQUAL_MSG(vec.size(),len,"Invalid vector length");
END_TEST_CASE()

BEGIN_TEST_CASE("should use default provided value and implemente operator[]")
  int len = 10;
  double val = nv_random_real();
  MESSAGE("Initial value is: "+(string)val);

  nvVecd vec(len,val);
  for(int i=0;i<len;++i) {
    REQUIRE_EQUAL(vec[i],val)
  }
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
