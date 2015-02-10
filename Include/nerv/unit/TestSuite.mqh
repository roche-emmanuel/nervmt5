
#include "TestCase.mqh"

class nvTestSuite
{
protected:
  // Name of this test suite:
  string _name;

  // List of test cases contained in this suite:
  nvTestCase *_cases[];

  // List of children suites contained in this suite:
  nvTestSuite *_suites[];

  // Parent test suite:
  nvTestSuite *_parent;

public:
  nvTestSuite(string name, nvTestSuite *parent = NULL)
  {
    _name = name;
    _parent = parent;
    Print("Creating test suite ", _name);
    ArrayResize(_cases, 0); // Set the array size to zero
    ArrayResize(_suites, 0); // Set the array size to zero
  }

  virtual ~nvTestSuite()
  {
    Print("Deleting test suite ", _name);
    // delete all the registered test cases:
    int num = ArraySize(_cases);
    for (int i = 0; i < num; ++i)
    {
      delete _cases[i];
    }

    // Clear the buffer:
    ArrayFree(_cases);

    // delete all the registered test suites:
    num = ArraySize(_suites);
    for (int i = 0; i < num; ++i)
    {
      delete _suites[i];
    }

    // Clear the buffer:
    ArrayFree(_suites);
  }

  // Add a new test case to this test suite:
  void addTestCase(nvTestCase *test)
  {
    int num = ArraySize(_cases);
    ArrayResize(_cases, num + 1); //
    _cases[num] = test;
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
    for (int i = 0; i < num; ++i)
    {
      if (_suites[i].getName() == sname)
      {
        Print("Retrieved existing test suite with name ", sname);
        return GetPointer(_suites[i]);
      }
    }

    // Create the new test suite:
    nvTestSuite *suite = new nvTestSuite(sname,GetPointer(this));

    // Add the new suite to the list:
    ArrayResize(_suites, num + 1); //
    _suites[num] = suite;

    // return the newly created test suite:
    return suite;
  }

  // Run the current test suite:
  void run()
  {
    Print("Entering Test Suite ", _name);

    // Execute all the children test suites:
    int num = ArraySize(_suites);
    for (int i = 0; i < num; ++i)
    {
      _suites[i].run();
    }

    // Execute all the test cases:
    num = ArraySize(_cases);
    for (int i = 0; i < num; ++i)
    {
      Print(_name, ": ", _cases[i].getName());
      int res = _cases[i].doTest();
      if (res == TEST_PASSED)
      {
        Print("=> Test PASSED");
      }
      else
      {
        Print("=> Test FAILED");
      }
    }

    Print("Leaving Test Suite ", _name);
  }
};
