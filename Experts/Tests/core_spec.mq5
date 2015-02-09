// Copyright 2015, NervTech
// https://wiki.singularityworld.net

#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"
#property version   "1.00"

// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core/LogManager.mqh>


BEGIN_TEST_SESSION

BEGIN_TEST_SUITE("My test suite")

BEGIN_TEST_CASE("should know how to add 1 and 1")
	ASSERT_EQUAL(1,1)	
END_TEST_CASE

END_TEST_SUITE

Print("Initializing Core tests.");

	string my = "my";
	int code = 42;
	bool val = true;
	string msg = "Here is "+my+" code: "+(string)42+" and this is "+(string)val;
	Print(msg);
	
{
  class MyClass
  {
  public:
    MyClass()
    {
      Print("Creating my class.");
    }
    ~MyClass()
    {
      Print("Deleting my class.");
    }
  };

  MyClass *obj = new MyClass();

  delete obj;
}

{
  class MyClass
  {
  public:
    MyClass()
    {
      Print("Creating my class 2.");
    }
    ~MyClass()
    {
      Print("Deleting my class 2.");
    }
  };

  MyClass *obj = new MyClass();

  delete obj;
}

// Retrieve instance of LogManager:
nvLogManager *lm = nvLogManager::instance();
if (lm != NULL)
{
  Print("LogManager instance is OK");
}
else
{
  Print("Invalid LogManager instance.");
}

return (INIT_SUCCEEDED);
END_TEST_SESSION
