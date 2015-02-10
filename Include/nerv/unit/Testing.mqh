//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include "TestManager.mqh"

#define BEGIN_TEST_SESSION(arg) void OnStart() \
  { \
    nvTestSuite* suite = nvTestManager::instance(); \
     
#define END_TEST_SESSION(arg) nvTestManager::instance().run(); \
  }

#define BEGIN_TEST_SUITE(sname) suite = suite.getOrCreateTestSuite(sname);

#define END_TEST_SUITE(arg) suite = suite.getParent();

#define BEGIN_TEST_CASE(tname) { \
    class TestClass : public nvTestCase { \
    public: \
      TestClass() { \
        _name = tname; \
      }; \
      ~TestClass() {}; \
      int doTest() { \
         
#define END_TEST_CASE(arg)  return TEST_PASSED; } \
  }; \
  TestClass* test = new TestClass(); \
  suite.addTestCase(test); \
  }

#define BEGIN_TEST_PACKAGE(pname) void test_package_##pname(nvTestSuite* parent) { \
  nvTestSuite* suite = parent;

#define END_TEST_PACKAGE(arg) }

#define LOAD_TEST_PACKAGE(pname) test_package_##pname(suite);

#define TOSTR(x) #x
#define SHOWERROR(msg) { \
    Print(__FILE__,"(",__LINE__,"): ",msg); \
    return TEST_FAILED; \
  }

#define ASSERT_MSG(val,msg) if(!(val)) SHOWERROR(msg)
#define ASSERT_EQUAL_MSG(v1,v2,msg) if(v1!=v2) SHOWERROR(msg)

#define ASSERT(val) ASSERT_MSG(val,"Assertion "+ TOSTR(val) + " failed.")
#define ASSERT_EQUAL(v1,v2) ASSERT_EQUAL_MSG(v1,v2,"Equality assertion failed: "+(string)v1+"!="+(string)v2)

//#import "shell32.dll"
//int ShellExecuteW(int hwnd,string Operation,string File,string Parameters,string Directory,int ShowCmd);
//#import

//void OnStart()
//  {
//   Shell32::ShellExecuteW(0,"open","http://mql5.com","","",3);
//  }
