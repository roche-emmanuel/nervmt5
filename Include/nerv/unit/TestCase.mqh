
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

  virtual int doTest()
  {
    // method should be overriden by test implementations.
    Print("ERROR: this should never be displayed!");
    return TEST_FAILED;
  }
};
