//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#define BEGIN_TEST_SESSION int OnInit() \
  { \
    nvTestManager* tman = nvTestManager::instance(); \
    nvTestSuite* suite = tman.getOrCreateTestSuite("default");

#define END_TEST_SESSION }

#define BEGIN_TEST_SUITE(sname) suite = tman.getOrCreateTestSuite(sname);

#define END_TEST_SUITE suite = tman.getOrCreateTestSuite("default");

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

  virtual int doTest(); // method should be overriden by test implementations.
};


class nvTestSuite
{
protected:
  string _name;
  nvTestCase *_cases[];

public:
  nvTestSuite(const string &name)
  {
    _name = name;
    Print("Creating test suite ", _name);
    ArrayResize(_cases, 0); // Set the array size to zero
  }

  ~nvTestSuite()
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
};


// The Test manager root class, which is also a test suite itself.
class nvTestManager : public nvTestSuite
{
protected:
  // Protected constructor and destructor:
  nvTestManager(void)
  {
    Print("Creating TestManager.");
    ArrayResize(_suites, 0); // Set the array size to zero
  };

  ~nvTestManager(void)
  {
    Print("Destroying TestManager.");
    // delete all the registered test suites:
    int num = ArraySize(_suites);
    for (int i = 0; i < num; ++i)
    {
      delete _suites[i];
    }

    // Clear the buffer:
    ArrayFree(_suites);
  };

public:
  // Retrieve the instance of this log manager:
  static nvTestManager *instance()
  {
    static nvTestManager singleton;
    return GetPointer(singleton);
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
};
