
#include <nerv/unit/Testing.mqh>
#include <nerv/math.mqh>

BEGIN_TEST_PACKAGE(math_specs)

BEGIN_TEST_SUITE("Math components")

BEGIN_TEST_SUITE("Vecd class")

BEGIN_TEST_CASE("should be able to create a vector")
  int len = 10;
  nvVecd vec(len);
  REQUIRE_EQUAL_MSG(vec.size(),len,"Invalid vector length");
END_TEST_CASE()

BEGIN_TEST_CASE("should use default provided value and implemente operator[]")
  int len = 10;
  double val = nv_random_real();
  //MESSAGE("Initial value is: "+(string)val);

  nvVecd vec(len,val);
  for(int i=0;i<len;++i) {
    REQUIRE_EQUAL(vec[i],val);
  }
END_TEST_CASE()

BEGIN_TEST_CASE("should support setting element value")
  int len = 10;
  double val = 1.0;
  nvVecd vec(len,val);

  REQUIRE_EQUAL(vec[0],val);
  vec.set(0,1.0);
  REQUIRE_EQUAL(vec.get(0),1.0);
END_TEST_CASE()

BEGIN_TEST_CASE("should have equality operator")
  int len = 10;
  double val = 1.0;
  nvVecd vec1(len,val);
  nvVecd vec2(len,val);

  REQUIRE(vec1==vec2);
  vec2.set(1,val+1.0);
  REQUIRE(vec1!=vec2);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_SUITE()

END_TEST_PACKAGE()
