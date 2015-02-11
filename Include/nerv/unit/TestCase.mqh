
#include "TestResult.mqh"

enum nvTestStatusCode
{
  TEST_PASSED,
  TEST_FAILED
};

class nvTestSuite;

class nvTestCase : public CObject
{
protected:
  string _name;


public:
  nvTestCase() {};

  ~nvTestCase() {};

  string getName() const
  {
    return _name;
  }

  nvTestResult* run(nvTestSuite* suite)
  {
    nvTestResult* result = new nvTestResult(_name,suite);
    // Start a timer:
    uint start=GetTickCount();
    int status = doTest();
    uint end=GetTickCount();
    result.setStatus(status);
    result.setDuration(((double)(end-start))/1000.0);
    return result;
  }

  virtual int doTest()
  {
    // method should be overriden by test implementations.
    Print("ERROR: this should never be displayed!");
    return TEST_FAILED;
  }
};
