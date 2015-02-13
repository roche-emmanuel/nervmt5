//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include "TestManager.mqh"

#define BEGIN_TEST_SESSION(location) void OnStart() \
  { \
    nvTestManager* tman = nvTestManager::instance(); \
    tman.setTargetLocation(location); \
    nvTestSuite* suite = tman;

#define END_TEST_SESSION(arg) nvTestManager::instance().run(); \
  }

#define BEGIN_TEST_SUITE(sname) if(true) { suite = suite.getOrCreateTestSuite(sname);

#define XBEGIN_TEST_SUITE(sname) if(false) { suite = suite.getOrCreateTestSuite(sname);

#define END_TEST_SUITE(arg) suite = suite.getParent(); }

#define BEGIN_TEST_CASE_BODY(tname) class TestClass : public nvTestCase { \
  public: \
    TestClass() { \
      _name = tname; \
    }; \
    ~TestClass() {}; \
    int doTest() { \
      int __test_result__ = TEST_PASSED;


#define BEGIN_TEST_CASE(tname) if(true) { \
    BEGIN_TEST_CASE_BODY(tname)

#define XBEGIN_TEST_CASE(tname) if(false) { \
    BEGIN_TEST_CASE_BODY(tname)

#define END_TEST_CASE(arg)  return __test_result__; } \
  }; \
  TestClass* test = new TestClass(); \
  suite.addTestCase(test); \
  }

#define BEGIN_TEST_PACKAGE(pname) void test_package_##pname(nvTestSuite* parent) { \
    nvTestSuite* suite = parent;

#define END_TEST_PACKAGE(arg) }

#define LOAD_TEST_PACKAGE(pname) if(true) { test_package_##pname(suite); }
#define XLOAD_TEST_PACKAGE(pname) if(false) { test_package_##pname(suite); }

#define TOSTR(x) #x
#define SHOWINFO(msg) writeMessage(TimeLocal(), SEV_INFO, msg, __FILE__, __LINE__);
#define SHOWERROR(msg) { \
    writeMessage(TimeLocal(), SEV_ERROR, msg, __FILE__, __LINE__); \
    __test_result__ = TEST_FAILED; \
  }

#define SHOWFATAL(msg) { \
    writeMessage(TimeLocal(), SEV_FATAL, msg, __FILE__, __LINE__); \
    return TEST_FAILED; \
  }

#define MESSAGE(msg) SHOWINFO(msg)
#define DISPLAY(val) MESSAGE(TOSTR(val) +" = "+(string)(val))

#define ASSUME_MSG(val,msg) if(!(val)) SHOWINFO(msg)
#define ASSERT_MSG(val,msg) if(!(val)) SHOWERROR(msg)
#define REQUIRE_MSG(val,msg) if(!(val)) SHOWFATAL(msg)
#define ASSERT_EQUAL_MSG(v1,v2,msg) if(v1!=v2) SHOWERROR(msg)
#define REQUIRE_EQUAL_MSG(v1,v2,msg) if(v1!=v2) SHOWFATAL(msg)

#define ASSUME(val) ASSUME_MSG(val,"Assumption "+ TOSTR(val) + " is invalid.")
#define ASSERT(val) ASSERT_MSG(val,"Assertion "+ TOSTR(val) + " failed.")
#define REQUIRE(val) REQUIRE_MSG(val,"Assertion "+ TOSTR(val) + " failed.")
#define ASSERT_EQUAL(v1,v2) ASSERT_EQUAL_MSG(v1,v2,"Equality assertion failed: "+(string)v1+"!="+(string)v2)
#define REQUIRE_EQUAL(v1,v2) REQUIRE_EQUAL_MSG(v1,v2,"Equality assertion failed: "+(string)v1+"!="+(string)v2)
