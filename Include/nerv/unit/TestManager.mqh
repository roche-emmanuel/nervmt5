
#include "TestSuite.mqh"

// The Test manager root class, which is also a test suite itself.
class nvTestManager : public nvTestSuite
{
protected:
  // Protected constructor and destructor:
  nvTestManager() : nvTestSuite("Test session")
  {
    Print("Creating TestManager.");
  };

  ~nvTestManager(void)
  {
    Print("Destroying TestManager.");
  };

public:
  // Retrieve the instance of this log manager:
  static nvTestManager *instance()
  {
    static nvTestManager singleton;
    return GetPointer(singleton);
  }

  void run()
  {
    nvTestSessionResult sessionResult;
    int npass, nfail;
    run(GetPointer(sessionResult),npass,nfail);
  }
};
