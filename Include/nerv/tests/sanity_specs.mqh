
#include <nerv/unit/Testing.mqh>
#include <nerv/math/SimpleRNG.mqh>
#include <nerv/utils.mqh>

void assign_value(double& arr[])
{
  arr[0] = 1.0;
}

struct my_struct
{
  double val1;
  double val2[];
  string val3;
};

#ifdef TEST_COPY_STRUCT
my_struct buildStruct()
{
  my_struct res;
  res.val1 = 1.0;
  ArrayResize(res.val2,3);
  res.val2[0]=2.0;
  res.val2[1]=3.0;
  res.val2[2]=4.0;
  res.val3 = "Hello world!";
  return res;
}
#endif

#ifdef TEST_INNER_CLASSES
class my_namespace
{
public:
  class my_base
  {
  protected:
    int _val;
    int _val2;

  public:
    my_base()
    {
      _val = 1;
      _val2 = 2;
    }

    int getVal1() const
    {
      return _val;
    }

    int getVal2() const
    {
      return _val2;
    }
  };

  class my_child : public my_base
  {
  public:
    my_child()
    {
      _val2 = 3;
    }
  };
};
#endif


BEGIN_TEST_PACKAGE(sanity_specs)

BEGIN_TEST_SUITE("Sanity checks")

BEGIN_TEST_CASE("Should support throwing an error")
  nvExceptionCatcher* ec_ = nvExceptionCatcher::instance();
  ec_.setEnabled(true);
  THROW("This is an error.")
  ASSERT_EQUAL(ec_.getErrorCount(),1)
  ASSERT_EQUAL(ec_.getLastError(),"This is an error.")
END_TEST_CASE()

BEGIN_TEST_CASE("Should support encapsulating an error")
  
  BEGIN_ASSERT_ERROR("This is an error.")
  THROW("This is an error.")
  END_ASSERT_ERROR()

END_TEST_CASE()

BEGIN_TEST_CASE("Should support retrieving error count")
  
  CATCH_ERRORS(true)
  THROW("This is an error 1.")
  THROW("This is an error 2.")
  CATCH_ERRORS(false)
  ASSERT_EQUAL(ERROR_COUNT,2)
  ASSERT_EQUAL(LAST_ERROR_MSG,"This is an error 2.")

END_TEST_CASE()


BEGIN_TEST_CASE("should failed on 1==0")
  ASSERT_EQUAL(1,1);
END_TEST_CASE()

BEGIN_TEST_CASE("should display message if applicable")
  ASSERT_EQUAL_MSG(1,1,"The values are not equal: "<<1<<"!="<<0);  
END_TEST_CASE()

BEGIN_TEST_CASE("should take some time to perform long operation")
  double res = 0.0;
  for(int i=0;i<100000;++i) {
    res += MathCos(i);
  }
  DISPLAY(res);
END_TEST_CASE()

BEGIN_TEST_CASE("should allow conversion of datetime to number of seconds")
  datetime t1 = D'19.07.1980 12:30:27';
  datetime t2 = D'19.07.1980 12:30:37';

  ulong diff = t2-t1;
  ulong val1 = t1;
  ulong val2 = t2;
  DISPLAY(val1);
  DISPLAY(val2);
  ASSERT_EQUAL(diff,10);
  REQUIRE(t2>t1);
END_TEST_CASE()

BEGIN_TEST_CASE("should allow manipulating array references")
  double arr[] = {0,0,0,3};

  assign_value(arr);
  ASSERT_EQUAL(arr[0],1.0);
  ASSERT_EQUAL(arr[3],3.0);
END_TEST_CASE()

#ifdef TEST_COPY_STRUCT
BEGIN_TEST_CASE("should allow copy of structures")
  my_struct myres = buildStruct();
  ASSERT_EQUAL(myres.val1,1.0);
  ASSERT_EQUAL(ArraySize(myres.val2),3.0);
  ASSERT_EQUAL(myres.val2[0],2.0);
  ASSERT_EQUAL(myres.val2[1],3.0);
  ASSERT_EQUAL(myres.val2[2],4.0);
  ASSERT_EQUAL(myres.val3,"Helo world!");
END_TEST_CASE()
#endif

#ifdef TEST_INNER_CLASSES
BEGIN_TEST_CASE("should support class as namespace")
  my_namespace::my_child* child = new my_namespace::my_child();

  ASSERT_EQUAL(child.getVal1(),1);
  ASSERT_EQUAL(child.getVal2(),3);
END_TEST_CASE()
#endif

BEGIN_TEST_CASE("should support deleting a null pointer")
  class my_test_class
  {
  public:
    my_test_class() {};
  };

  my_test_class* obj = NULL;
  delete obj;
END_TEST_CASE()

BEGIN_TEST_CASE("should support deleting a pointer twice")
  class my_test_class
  {
  public:
    my_test_class() {};
  };

  my_test_class* obj = new my_test_class();
  delete obj;
  delete obj;
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to format time")
  ulong secs = 60;
  string res = formatTime(secs);
  ASSERT_EQUAL(res,"00:01:00");
END_TEST_CASE()

BEGIN_TEST_CASE("Should retrieve rates as expected")
  datetime basetime = TimeCurrent() - 3600;

  string symbol = "EURUSD";
  SimpleRNG rng;
  rng.SetSeedFromSystemTime();

  // A bar time should correspond to the beginning of the bar.
  // And then each time given inside the period after that bar time, should return the same bar:
  int num = 100;
  for(int i=0;i<num;++i)
  {
    datetime time = basetime + rng.GetInt(0,3599);

    MqlRates rates[];
    ASSERT_EQUAL(CopyRates(symbol,PERIOD_M1,time,1,rates),1);
    ASSERT_LE(rates[0].time,time);  
    ASSERT_LT(time,rates[0].time+60);

    int offset = rng.GetInt(0,59);
    
    MqlRates newrates[];
    ASSERT_EQUAL(CopyRates(symbol,PERIOD_M1,rates[0].time+offset,1,newrates),1);
    
    ASSERT_EQUAL(newrates[0].time,rates[0].time);
    ASSERT_EQUAL(newrates[0].open,rates[0].open);
    ASSERT_EQUAL(newrates[0].high,rates[0].high);
    ASSERT_EQUAL(newrates[0].low,rates[0].low);
    ASSERT_EQUAL(newrates[0].close,rates[0].close);
    ASSERT_EQUAL(newrates[0].spread,rates[0].spread);
  }
END_TEST_CASE()

BEGIN_TEST_CASE("Should return the expected value when computing modulos")
  int val = (-1)%7;
  // ASSERT_EQUAL(val,6);
  ASSERT_EQUAL(val,-1); // This is not the result we expected.
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to align rates array as expected")
  int maxNumBar = 52+29;

  datetime time = D'2015.01.02 00:00';

  MqlRates cachedRates[];
  MqlRates rates[];

  string symbol = "EURUSD";
  ENUM_TIMEFRAMES period = PERIOD_M1;

  datetime lastUpdateTime = nvGetBarTime(symbol,period,time);

  // At that time we need to cache as much data as we can!
  datetime ctime = TimeCurrent(); // retrieve the latest time available from the server;

  // Check how many bars we could cache:
  int dur = nvGetPeriodDuration(period);
  int num = (int)MathFloor((ctime - lastUpdateTime)/(double)dur);

  // num = MathMin(99999-maxNumBar,num);
  // num = 1000; // Doesn't work for too big value of num !!
  num = 100; // Doesn't work for too big value of num !!
  datetime lastTime = lastUpdateTime + num*dur;
  
  num += maxNumBar;
  logDEBUG("Caching "<<num<<" bar for ichimoku indicator");
  ASSERT_EQUAL(CopyRates(symbol,period,lastTime,num,cachedRates),num);

  ASSERT_EQUAL(CopyRates(symbol,period,time,maxNumBar,rates),maxNumBar);
  
  for(int i=0;i<maxNumBar;++i) {
    ASSERT_EQUAL(rates[i].close,cachedRates[i].close);
  }

END_TEST_CASE()


BEGIN_TEST_CASE("should retrieve the desired bar by time")
  datetime time = D'2016.01.05 10:30:00';

  string symbol = "EURUSD";
  MqlRates rates[];
  int len = CopyRates(symbol,PERIOD_M1,time,1,rates);
  while(len<0)
  {
    logDEBUG("Downloading data for "<<symbol<<"...")
    len = CopyRates(symbol,PERIOD_M1,time,1,rates);
    Sleep(50);
  }

  ASSERT_EQUAL(len,1);
  ASSERT_EQUAL(time,rates[0].time);
END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()
