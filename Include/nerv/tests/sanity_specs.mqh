
#include <nerv/unit/Testing.mqh>

BEGIN_TEST_PACKAGE(sanity_specs)

BEGIN_TEST_SUITE("Sanity checks")
  
BEGIN_TEST_CASE("should failed on 1==0")
  ASSERT_EQUAL(1,0);
END_TEST_CASE()

BEGIN_TEST_CASE("should display message if applicable")
  ASSERT_EQUAL_MSG(1,0,"The values are not equal: "+(string)1+"!="+(string)0);  
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
