
#include <nerv/unit/Testing.mqh>

BEGIN_TEST_PACKAGE(sanity_specs)

BEGIN_TEST_SUITE("Sanity checks")

BEGIN_TEST_CASE("Dummy test 1")
  ASSERT_EQUAL(1,1);
END_TEST_CASE()
BEGIN_TEST_CASE("Dummy test 2")
  ASSERT_EQUAL(1,1);
END_TEST_CASE()
BEGIN_TEST_CASE("Dummy test 3")
  ASSERT_EQUAL(1,1);
END_TEST_CASE()
BEGIN_TEST_CASE("Dummy test 4")
  ASSERT_EQUAL(1,1);
END_TEST_CASE()
BEGIN_TEST_CASE("Dummy test 5")
  ASSERT_EQUAL(1,1);
END_TEST_CASE()

BEGIN_TEST_CASE("Dummy test 6")
  ASSERT_EQUAL(1,1);
END_TEST_CASE()
BEGIN_TEST_CASE("Dummy test 7")
  ASSERT_EQUAL(1,1);
END_TEST_CASE()
BEGIN_TEST_CASE("Dummy test 8")
  ASSERT_EQUAL(1,1);
END_TEST_CASE()
BEGIN_TEST_CASE("Dummy test 9")
  ASSERT_EQUAL(1,1);
END_TEST_CASE()
BEGIN_TEST_CASE("Dummy test 10")
  ASSERT_EQUAL(1,1);
END_TEST_CASE()

BEGIN_TEST_CASE("should failed on 1==0")
  ASSERT_EQUAL(1,0);
END_TEST_CASE()

BEGIN_TEST_CASE("should display message if applicable")
  ASSERT_EQUAL_MSG(1,0,"The values are not equal: "+(string)1+"!="+(string)0);  
END_TEST_CASE()

BEGIN_TEST_CASE("should take some time to perform long operation")
  double res = 0.0;
  for(int i=0;i<100000;++i) {
    res += MathCos(i);
  }
  DISPLAY(res)
END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()
