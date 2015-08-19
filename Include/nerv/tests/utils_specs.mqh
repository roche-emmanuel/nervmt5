
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

BEGIN_TEST_CASE("Should be able to retrieve the base currency")
  ASSERT_EQUAL("EUR",nvGetBaseCurrency("EURUSD"));
  ASSERT_EQUAL("NZD",nvGetBaseCurrency("NZDUSD"));
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to retrieve the quote currency")
  ASSERT_EQUAL("USD",nvGetQuoteCurrency("EURUSD"));
  ASSERT_EQUAL("GBP",nvGetQuoteCurrency("EURGBP"));
END_TEST_CASE()

BEGIN_TEST_CASE("Should compute point value properly")
  ASSERT_EQUAL(nvGetPointValue("EURUSD"),1.0);
  ASSERT_EQUAL(nvGetPointValue("EURGBP"),1.0);
  ASSERT_EQUAL(nvGetPointValue("EURJPY"),100.0);
END_TEST_CASE()

BEGIN_TEST_CASE("Should normalize lot size properly")
  ASSERT_EQUAL(nvNormalizeLotSize(1.234,"EURUSD"),1.23);
  ASSERT_EQUAL(nvNormalizeLotSize(1.3488,"EURJPY"),1.34);
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide proper period duration")
  ASSERT_EQUAL(nvGetPeriodDuration(PERIOD_H4),3600 * 4);

  BEGIN_ASSERT_ERROR("Unsupported period value PERIOD_MN1")
    nvGetPeriodDuration(PERIOD_MN1);
  END_ASSERT_ERROR();

  // Should still work if we concert the value to/from int:
  int val = (int)PERIOD_H4;
  // logDEBUG("Period converted to int: "<<val);

  ENUM_TIMEFRAMES p2 = (ENUM_TIMEFRAMES)val;
  // logDEBUG("Period converted back to TimeFrame: "<<EnumToString(p2));
  ASSERT_EQUAL(nvGetPeriodDuration(p2),3600 * 4);
END_TEST_CASE()

BEGIN_TEST_CASE("Should support retriving period by index")
  int num = 21;
  for(int i=0;i<num;++i)
  {
    ENUM_TIMEFRAMES p = nvGetPeriodByIndex(i);
    int j = nvGetPeriodIndex(p);
    ASSERT_EQUAL(i,j);
  }
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to check if a symbol is valid")
  REQUIRE_EQUAL(nvIsSymbolValid("XXXYYY"),false);
  REQUIRE_EQUAL(nvIsSymbolValid("EURUSD"),true);
END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()

