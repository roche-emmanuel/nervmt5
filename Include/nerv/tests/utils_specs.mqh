
#include <nerv/unit/Testing.mqh>
#include <nerv/utils.mqh>

BEGIN_TEST_PACKAGE(utils_specs)
  
BEGIN_TEST_SUITE("Utils functions tests")
  
BEGIN_TEST_CASE("Should support removing an item from an array")
  int arr1[];
  ArrayResize( arr1, 6 );
  int src1[] = {1,2,3,4,5,6};
  ArrayCopy( arr1, src1, 0, 0);
  REQUIRE_EQUAL(ArraySize( arr1 ),6)
  nvRemoveArrayItem(arr1,0);
  REQUIRE_EQUAL(ArraySize( arr1 ),5)
  REQUIRE_EQUAL(arr1[0],2)
  REQUIRE_EQUAL(arr1[4],6)
  
  nvRemoveArrayItem(arr1,1);
  REQUIRE_EQUAL(arr1[1],4);

  double arr2[];
  ArrayResize( arr2, 6 );
  int src2[] = {1,2,3,4,5,6};
  ArrayCopy( arr2, src2, 0, 0);
  nvRemoveArrayItem(arr2,0);
  REQUIRE_EQUAL(ArraySize( arr2 ),5)
  REQUIRE_EQUAL(arr2[0],2)
  REQUIRE_EQUAL(arr2[4],6)
  
  nvRemoveArrayItem(arr2,1);
  REQUIRE_EQUAL(arr2[1],4);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()

