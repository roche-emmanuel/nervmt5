
#include <nerv/unit/Testing.mqh>
#include <nerv/trade/rrl/HistoryMap.mqh>

BEGIN_TEST_PACKAGE(historymap_specs)

BEGIN_TEST_SUITE("HistoryMap class")

BEGIN_TEST_CASE("should be able to add data and write channels")
  
  {
    nvHistoryMap history;
    history.add("test_channel_1",1.1);
    history.add("test_channel_1",2.2);
    history.add("test_channel_2",3.3);
    history.add("test_channel_2",4.4);
    history.add("test_channel_2",5.5);
  }

  nvVecd vec1("test_channel_1.txt");
  nvVecd vec2("test_channel_2.txt");
  double arr1[] = {1.1, 2.2};
  double arr2[] = {3.3, 4.4, 5.5};

  REQUIRE_EQUAL(vec1,arr1);
  REQUIRE_EQUAL(vec2,arr2);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
