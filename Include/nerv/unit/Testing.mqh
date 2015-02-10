//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#define BEGIN_TEST_SESSION int OnInit() \
  { \
    nvTestSuite* suite = nvTestManager::instance(); \
     
#define END_TEST_SESSION nvTestManager::instance().run(); \
  Print("Will now finish this."); \
  ExpertRemove(); \
  return (INIT_SUCCEEDED); \
  }

#define BEGIN_TEST_SUITE(sname) suite = suite.getOrCreateTestSuite(sname);

#define END_TEST_SUITE suite = suite.getParent();

#define BEGIN_TEST_CASE(tname) { \
    class TestClass : public nvTestCase { \
    public: \
      TestClass() { \
        _name = tname; \
      }; \
      ~TestClass() {}; \
      int doTest() { \
         
#define END_TEST_CASE  return TEST_PASSED; } \
  }; \
  TestClass* test = new TestClass(); \
  suite.addTestCase(test); \
  }

#define ASSERT_EQUAL_MSG(v1,v2,msg) if(v1!=v2) { \
    Print(__FILE__,"(",__LINE__,"): ",msg); \
    return TEST_FAILED; \
  }

#define ASSERT_EQUAL(v1,v2) ASSERT_EQUAL_MSG(v1,v2,"Equality assertion failed: "+(string)v1+"!="+(string)v2)

//#import "shell32.dll"
//int ShellExecuteW(int hwnd,string Operation,string File,string Parameters,string Directory,int ShowCmd);
//#import

//void OnStart()
//  {
//   Shell32::ShellExecuteW(0,"open","http://mql5.com","","",3);
//  }

enum nvTestStatusCode
{
  TEST_PASSED,
  TEST_FAILED
};

class nvTestCase
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

  virtual int doTest() {
    // method should be overriden by test implementations.
    Print("ERROR: this should never be displayed!");
    return TEST_FAILED;
  }
};


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
    nvTestSuite *suite = new nvTestSuite(sname);

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
};
