
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/math.mqh>

BEGIN_TEST_PACKAGE(map_specs)

BEGIN_TEST_SUITE("ObjectMap class")

BEGIN_TEST_CASE("should be able to create a map")
  nvObjectMap map;
  REQUIRE_EQUAL(map.size(),0);
  REQUIRE_EQUAL(map.empty(),true);
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to add and retrieve object")
  nvObjectMap map;

  nvVecd vec;
  map.set("my_vec",GetPointer(vec),false);
  REQUIRE_EQUAL(map.size(),1);
  REQUIRE_EQUAL(map.empty(),false);
  REQUIRE_EQUAL(map.get("my_vec"),GetPointer(vec));
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to get keys and values")
  nvObjectMap map;

  nvVecd vec;
  nvVecd vec2;
  nvVecd* vec3 = new nvVecd();
  map.set("my_vec",GetPointer(vec),false);
  map.set("my_vec2",GetPointer(vec2),false);
  map.set("my_vec3",vec3);

  REQUIRE_EQUAL(map.size(),3);
  REQUIRE_EQUAL(map.getKey(0),"my_vec");
  REQUIRE_EQUAL(map.getValue(2),vec3);
  REQUIRE(map.get("dummy")==NULL);
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to clear")
  nvObjectMap map;

  nvVecd vec;
  nvVecd vec2;
  nvVecd* vec3 = new nvVecd();
  map.set("my_vec",GetPointer(vec),false);
  map.set("my_vec2",GetPointer(vec2),false);
  map.set("my_vec3",vec3);

  REQUIRE_EQUAL(map.size(),3);
  map.clear();
  REQUIRE_EQUAL(map.size(),0);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
