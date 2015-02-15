
#include <nerv/unit/Testing.mqh>

BEGIN_TEST_PACKAGE(sanity_specs)

BEGIN_TEST_SUITE("Sanity checks")

BEGIN_TEST_CASE("should failed on 1==0")
  ASSERT_EQUAL(1,1);
END_TEST_CASE()

BEGIN_TEST_CASE("should display message if applicable")
  ASSERT_EQUAL_MSG(1,1,"The values are not equal: "<<1<<"!="<<0);  
END_TEST_CASE()

BEGIN_TEST_CASE("should take some time to perform long operation")
  double res = 0.0;
  for(int i=0;i<100000;++i) {
    res += MathCos(i);
  }
  DISPLAY(res);
END_TEST_CASE()

BEGIN_TEST_CASE("should allow conversion of datetime to number of seconds")
  datetime t1 = D'19.07.1980 12:30:27';
  datetime t2 = D'19.07.1980 12:30:37';

  ulong diff = t2-t1;
  ulong val1 = t1;
  ulong val2 = t2;
  DISPLAY(val1);
  DISPLAY(val2);
  REQUIRE_EQUAL(diff,10);
  REQUIRE(t2>t1);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
