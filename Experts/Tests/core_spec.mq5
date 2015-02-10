// Copyright 2015, NervTech
// https://wiki.singularityworld.net

#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"
#property version   "1.00"

// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core/LogManager.mqh>


BEGIN_TEST_SESSION()

BEGIN_TEST_SUITE("Sanity tests")

BEGIN_TEST_CASE("should failed on 1==0")
	ASSERT_EQUAL(1,0);
END_TEST_CASE()

BEGIN_TEST_CASE("should display message if applicable")
	ASSERT_EQUAL_MSG(1,0,"The values are not equal: "+(string)1+"!="+(string)0);	
END_TEST_CASE()

BEGIN_TEST_CASE("should have a valid log manage pointer")
	nvLogManager* lm = nvLogManager::instance();
	ASSERT(lm==NULL);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_SESSION()
