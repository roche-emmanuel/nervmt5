
#include <nerv/unit/Testing.mqh>
#include <nerv/math.mqh>

BEGIN_TEST_PACKAGE(simplerng_specs)

BEGIN_TEST_SUITE("SimpleRNG class")

BEGIN_TEST_CASE("Should be able to generate random integers")
  SimpleRNG rnd;
  rnd.SetSeedFromSystemTime();

  int num = 1000;
  int mini=100;
  int maxi= 0;
  int val;
  for(int i=0;i<num;++i)
  {
    val = rnd.GetInt(0,10);
    if(val<mini)
      mini = val;
    if(val>maxi)
      maxi = val;
  }
  ASSERT_EQUAL(maxi,10);
  ASSERT_EQUAL(mini,0);
END_TEST_CASE()

BEGIN_TEST_CASE("Should throw an error on invalid integer range")
  SimpleRNG rnd;
  rnd.SetSeedFromSystemTime();

  BEGIN_ASSERT_ERROR("Invalid period order: ")
    rnd.GetInt(10,8);
  END_ASSERT_ERROR();
END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()
