
#include <Object.mqh>
#include <Arrays/List.mqh>

class nvTestSuite;

class nvTestSessionResult : public CObject
{
protected:
  CList _suites; // Keep a reference on all suites.
  CList _testResults; // keep a reference on all test results.

public:
  nvTestSessionResult() {
    Print("Creating TestSessionResult.");
  };

  ~nvTestSessionResult() {
    Print("Deleting TestSessionResult.");
  };

  void addTestSuite(nvTestSuite* suite)
  {
    _suites.Add(suite);
  }

  void addTestResult(nvTestResult* result)
  {
    _testResults.Add(result);
  }
};
