
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
  nvTestResult* _currentResult;

public:
  nvTestCase() : _currentResult(NULL) {};

  ~nvTestCase() {};

  string getName() const
  {
    return _name;
  }

  nvTestResult *run(nvTestSuite *suite)
  {
    nvTestResult *result = new nvTestResult(_name, suite);

    // Assign current result:
    _currentResult = result;

    // Start a timer:
    uint start = GetTickCount();
    int status = doTest();
    uint end = GetTickCount();

    _currentResult = NULL;

    result.setStatus(status);
    result.setDuration(((double)(end - start)) / 1000.0);
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
      Print("ERROR: Invalid current result.");
    }

    _currentResult.addMessage(time,severity,content,filename,lineNum);
  }
};
