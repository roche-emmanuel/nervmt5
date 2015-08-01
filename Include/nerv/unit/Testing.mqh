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
  nvTestManager::instance().release(); \
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
#define WRITEMSG(sev,msg) { \
  nvStringStream __ss__; \
  __ss__ << msg; \
  writeMessage(TimeLocal(), sev, __ss__.str(), __FILE__, __LINE__); \
}

#define SHOWINFO(msg) WRITEMSG(SEV_INFO,msg) 

#define SHOWERROR(msg) { \
    WRITEMSG(SEV_ERROR,msg); \
    __test_result__ = TEST_FAILED; \
  }

#define SHOWFATAL(msg) { \
    WRITEMSG(SEV_FATAL,msg); \
    return TEST_FAILED; \
  }

#define CATCH_ERRORS(enabled) nvExceptionCatcher::instance().setEnabled(enabled);

#define LAST_ERROR_MSG nvExceptionCatcher::instance().getLastError()
#define ERROR_COUNT nvExceptionCatcher::instance().getErrorCount()

#define MESSAGE(msg) SHOWINFO(msg)
#define DISPLAY(val) MESSAGE(TOSTR(val) << " = " << val)

#define ASSUME_MSG(val,msg) if(!(val)) SHOWINFO(msg)
#define ASSERT_MSG(val,msg) if(!(val)) SHOWERROR(msg)
#define REQUIRE_MSG(val,msg) if(!(val)) SHOWFATAL(msg)
#define ASSERT_EQUAL_MSG(v1,v2,msg) if(v1!=v2) SHOWERROR(msg)
#define REQUIRE_EQUAL_MSG(v1,v2,msg) if(v1!=v2) SHOWFATAL(msg)
#define REQUIRE_LT_MSG(v1,v2,msg) if(v1>=v2) SHOWFATAL(msg)
#define REQUIRE_GT_MSG(v1,v2,msg) if(v1<=v2) SHOWFATAL(msg)
#define REQUIRE_LE_MSG(v1,v2,msg) if(v1>v2) SHOWFATAL(msg)
#define REQUIRE_GE_MSG(v1,v2,msg) if(v1<v2) SHOWFATAL(msg)
#define REQUIRE_NOT_EQUAL_MSG(v1,v2,msg) if(v1==v2) SHOWFATAL(msg)
#define REQUIRE_CLOSE_MSG(v1,v2,eps,msg) if(v1!=v2 && MathAbs(v1-v2)/(0.5*(MathAbs(v1)+MathAbs(v2))) > eps) SHOWFATAL(msg)
#define REQUIRE_VALID_PTR_MSG(ptr,msg) if(!IS_VALID_POINTER(ptr)) SHOWFATAL(msg)
#define REQUIRE_NULL_PTR_MSG(ptr,msg) if(IS_VALID_POINTER(ptr)) SHOWFATAL(msg)
#define REQUIRE_NULL_MSG(ptr,msg) if(ptr!=NULL) SHOWFATAL(msg)
#define REQUIRE_NOT_NULL_MSG(ptr,msg) if(ptr==NULL) SHOWFATAL(msg)

#define REQUIRE_ERROR_MSG(msg) REQUIRE_EQUAL_MSG(LAST_ERROR_MSG,msg,"Invalid expected error message.")
#define REQUIRE_ERROR_COUNT(count) REQUIRE_EQUAL_MSG(ERROR_COUNT,count,"Invalid expected error count.")

#define ASSUME(val) ASSUME_MSG(val,"Assumption "<< TOSTR(val) << " is invalid.")
#define ASSERT(val) ASSERT_MSG(val,"Assertion "<< TOSTR(val) << " failed.")
#define REQUIRE(val) REQUIRE_MSG(val,"Assertion "<< TOSTR(val) << " failed.")
#define ASSERT_EQUAL(v1,v2) ASSERT_EQUAL_MSG(v1,v2,"Equality assertion failed: "<<(v1)<<"!="<<(v2))
#define REQUIRE_EQUAL(v1,v2) REQUIRE_EQUAL_MSG(v1,v2,"Equality assertion failed: "<<(v1)<<"!="<<(v2))
#define REQUIRE_LT(v1,v2) REQUIRE_LT_MSG(v1,v2,"Lesser than assertion failed: "<<(v1)<<">="<<(v2))
#define REQUIRE_GT(v1,v2) REQUIRE_GT_MSG(v1,v2,"Greater than assertion failed: "<<(v1)<<"<="<<(v2))
#define REQUIRE_LE(v1,v2) REQUIRE_LE_MSG(v1,v2,"Lesser or equal assertion failed: "<<(v1)<<">"<<(v2))
#define REQUIRE_GE(v1,v2) REQUIRE_GE_MSG(v1,v2,"Greater or equal assertion failed: "<<(v1)<<"<"<<(v2))
#define REQUIRE_NOT_EQUAL(v1,v2) REQUIRE_NOT_EQUAL_MSG(v1,v2,"Not equality assertion failed: "<<(v1)<<"=="<<(v2))
#define REQUIRE_CLOSE(v1,v2,eps) REQUIRE_CLOSE_MSG(v1,v2,eps,"Close value assertion failed: relative_change("<<(v1)<<","<<(v2)<<") > "<<eps)
#define REQUIRE_VALID_PTR(ptr) REQUIRE_VALID_PTR_MSG(ptr,"Invalid pointer detected.")
#define REQUIRE_NULL_PTR(ptr) REQUIRE_NULL_PTR_MSG(ptr,"Non NULL pointer detected.")
#define REQUIRE_NULL(ptr) REQUIRE_NULL_MSG(ptr,"Non NULL pointer detected.")
#define REQUIRE_NOT_NULL(ptr) REQUIRE_NOT_NULL_MSG(ptr,"Non NULL pointer detected.")

#define BEGIN_REQUIRE_ERROR(msg) { string __err_msg = msg; CATCH_ERRORS(true);
#define END_REQUIRE_ERROR(arg) int __err_count = nvExceptionCatcher::instance().getErrorCount(); \
  string __last_err_msg = nvExceptionCatcher::instance().getLastError(); \
  CATCH_ERRORS(false); \
  REQUIRE_EQUAL_MSG(__err_count,1,"Invalid error count: "<< __err_count <<"!=1"); \
  if(__err_msg!="") { REQUIRE_EQUAL_MSG(__last_err_msg,__err_msg,"Invalid error message: '"<<__last_err_msg<<"' != '"<<__err_msg<<"'"); } }
