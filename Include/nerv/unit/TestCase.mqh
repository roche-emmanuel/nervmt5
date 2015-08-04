
#include "TestResult.mqh"
#include <nerv/core.mqh>

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
  int _assertCount;
  nvTestResult* _currentResult;

public:
  nvTestCase() : _currentResult(NULL), _assertCount(0) {};

  ~nvTestCase() {};

  string getName() const
  {
    return _name;
  }
  void incrementAsserts()
  {
    _assertCount++;
  }

  nvTestResult *run(nvTestSuite *suite)
  {
    logDEBUG("Entering test case '"<<_name<<"'")
    nvTestResult *result = new nvTestResult(_name, suite);

    // Assign current result:
    _currentResult = result;

    // Start a timer:
    uint start = GetTickCount();
    int status = doTest();
    uint end = GetTickCount();

    _currentResult = NULL;

    result.setAssertionCount(_assertCount);
    result.setStatus(status);
    result.setDuration(((double)(end - start)) / 1000.0);
    logDEBUG("Leaving test case '"<<_name<<"'")
    return result;
  }

  virtual int doTest()
  {
    // method should be overriden by test implementations.
    Print("ERROR: this should never be displayed!");
    return TEST_FAILED;
  }

  // Method used to write a message in the current test result:
  void writeMessage(datetime time, int severity, string content, string filename, int lineNum)
  {
    if (_currentResult == NULL)
    {
      logERROR("Invalid current result.");
    }

    if(severity==SEV_INFO) {
      logINFO(time<<": "<<content);
    }
    else {
      logERROR(time<<": "<<filename<<"("<<lineNum<<"): "<<content);
    }
    
    _currentResult.addMessage(time,severity,content,filename,lineNum);
  }
};
