
#include "TestCase.mqh"
#include "TestSessionResult.mqh"

#include <Arrays/List.mqh>

class nvTestSuite : public CObject
{
protected:
  // Name of this test suite:
  string _name;

  // List of test cases contained in this suite:
  CList _cases;

  // List of children suites contained in this suite:
  CList* _suites;

  // Parent test suite:
  nvTestSuite *_parent;

public:
  nvTestSuite(string name, nvTestSuite *parent = NULL)
  {
    _name = name;
    _parent = parent;
    Print("Creating test suite ", _name);
    _suites = new CList();
  }

  virtual ~nvTestSuite()
  {
    Print("Deleting test suite ", _name);
    // delete all the registered test cases:
    _cases.Clear();
    _suites.Clear();
    delete _suites;
  }

  // Add a new test case to this test suite:
  void addTestCase(nvTestCase *test)
  {
    _cases.Add(test);
  }

  string getName() const
  {
    return _name;
  }

  nvTestSuite *getParent() const
  {
    return _parent;
  }

  nvTestSuite *getOrCreateTestSuite(string sname)
  {
    // Check if we already have this suite in the list:
    nvTestSuite* suite = (nvTestSuite*)_suites.GetFirstNode();
    while(suite) {
      if (suite.getName() == sname)
      {
        Print("Retrieved existing test suite with name ", sname);
        return suite;
      }
      suite = (nvTestSuite*)_suites.GetNextNode();      
    }

    // Create the new test suite:
    //MessageBox("Creating suite "+sname+" with parent "+getName());
    suite = new nvTestSuite(sname,GetPointer(this));

    // Add the new suite to the list:
    _suites.Add(suite);

    // return the newly created test suite:
    return suite;
  }

  // Run the current test suite:
  void run(nvTestSessionResult* result, int& numPassed, int& numFailed)
  {
    Print("Entering Test Suite ", _name);
    numPassed = 0;
    numFailed = 0;

    // Resgiter this test suite:
    result.addTestSuite(GetPointer(this));
    
    // Execute all the children test suites:
    int npass, nfail;
    nvTestSuite* suite = (nvTestSuite*)this._suites.GetFirstNode();
    MessageBox("Found "+this._suites.Total()+" sub suites for "+getName());
    while(suite) {
      suite.run(result,npass,nfail);
      // increment our own counters:
      numPassed += npass;
      numFailed += nfail;
      suite = (nvTestSuite*)this._suites.GetNextNode();            
    }

    // Execute all the test cases:
    nvTestResult* tresult;
    nvTestCase* tcase = (nvTestCase*)_cases.GetFirstNode();
    while(tcase!=NULL) {
      Print(_name, ": ", tcase.getName());
      tresult = tcase.run(GetPointer(this));
      result.addTestResult(tresult);
      int res = tresult.getStatus();
      if (res == TEST_PASSED)
      {
        numPassed++;
        Print("=> Test PASSED");
      }
      else
      {
        numFailed++;
        Print("=> Test FAILED");
      }
      tcase = (nvTestCase*)_cases.GetNextNode();
    }

    int total = numPassed+numFailed;

    Print("Leaving Test Suite ", _name, ": Success ratio: ",numPassed,"/",total);
  }
};
