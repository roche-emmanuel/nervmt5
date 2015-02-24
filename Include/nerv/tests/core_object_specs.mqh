
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>

BEGIN_TEST_PACKAGE(core_object_specs)

BEGIN_TEST_SUITE("nvObject class")

BEGIN_TEST_CASE("should detect dynamic pointer")
  nvObject obj1;
  REQUIRE_EQUAL(IS_DYN_POINTER(obj1),false);
  nvObject* obj2 = new nvObject();
  REQUIRE_EQUAL(IS_DYN_POINTER(obj2),true);
  delete obj2;
  REQUIRE_EQUAL(IS_VALID_POINTER(obj2),false);
END_TEST_CASE()

END_TEST_SUITE()


END_TEST_PACKAGE()
