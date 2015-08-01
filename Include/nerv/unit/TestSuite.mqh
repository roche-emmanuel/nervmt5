
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
  nvTestSuite* _suites[];

  // Parent test suite:
  nvTestSuite *_parent;

public:
  nvTestSuite(string name, nvTestSuite *parent = NULL)
  {
    _name = name;
    _parent = parent;
    Print("Creating test suite ", _name);
    ArrayResize(_suites,0);
  }

  virtual ~nvTestSuite()
  {
    Print("Deleting test suite ", _name);
    release();
  }

  void release()
  {
    //Print("Releasing test suite ",_name);
    int num = ArraySize(_suites);
    for(int i = 0;i<num;++i) {
      //nvTestSuite* s = _suites[i];
      //Print("Deleting test suite ",s.getName());
      delete GetPointer(_suites[i]);
      //Print("Done deleting test suite.");
    }
    //Print("Resizing array.");
    ArrayResize(_suites,0);
    //Print("Done resizing array.");
    
    // delete all the registered test cases:
    _cases.Clear();
    //Print("Done releasing test suite ",_name);
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
    int num = ArraySize(_suites);
    for(int i = 0;i<num;++i) {
      if(_suites[i].getName() == sname) {
        Print("Retrieved existing test suite with name ", sname);
        return _suites[i];        
      }
    }

    // Create the new test suite:
    //MessageBox("Creating suite "+sname+" with parent "+getName());
    nvTestSuite* suite = new nvTestSuite(sname,GetPointer(this));

    // Add the new suite to the list:
    ArrayResize(_suites,num+1);
    _suites[num] = suite;

    // return the newly created test suite:
    return suite;
  }

  // Run the current test suite:
  void run(nvTestSessionResult* result, int& numPassed, int& numFailed)
  {
    // Print("Entering Test Suite ", _name);
    logDEBUG("Entering Test suite "<<_name)
    numPassed = 0;
    numFailed = 0;

    // Resgiter this test suite:
    result.addTestSuite(GetPointer(this));
    
    // Execute all the children test suites:
    int npass, nfail;
    int num = ArraySize(_suites);
    for(int i=0;i<num;++i) {
      _suites[i].run(result,npass,nfail);
      // increment our own counters:
      numPassed += npass;
      numFailed += nfail;      
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
        // Print("=> Test PASSED");
        logDEBUG("=> Test PASSED")
      }
      else
      {
        numFailed++;
        // Print("=> Test FAILED");
        logDEBUG("=> Test FAILED")
      }
      tcase = (nvTestCase*)_cases.GetNextNode();
    }

    int total = numPassed+numFailed;

    logDEBUG("Leaving Test suite "<<_name<<": Success ratio: "<<numPassed<<"/"<<total)
    // Print("Leaving Test Suite ", _name, ": Success ratio: ",numPassed,"/",total);
  }
};
