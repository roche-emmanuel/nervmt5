
#include <nerv/unit/Testing.mqh>

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
  REQUIRE_EQUAL(diff,10);
  REQUIRE(t2>t1);
END_TEST_CASE()

BEGIN_TEST_CASE("should allow manipulating array references")
  double arr[] = {0,0,0,3};

  assign_value(arr);
  REQUIRE_EQUAL(arr[0],1.0);
  REQUIRE_EQUAL(arr[3],3.0);
END_TEST_CASE()

#ifdef TEST_COPY_STRUCT
BEGIN_TEST_CASE("should allow copy of structures")
  my_struct myres = buildStruct();
  REQUIRE_EQUAL(myres.val1,1.0);
  REQUIRE_EQUAL(ArraySize(myres.val2),3.0);
  REQUIRE_EQUAL(myres.val2[0],2.0);
  REQUIRE_EQUAL(myres.val2[1],3.0);
  REQUIRE_EQUAL(myres.val2[2],4.0);
  REQUIRE_EQUAL(myres.val3,"Helo world!");
END_TEST_CASE()
#endif

#ifdef TEST_INNER_CLASSES
BEGIN_TEST_CASE("should support class as namespace")
  my_namespace::my_child* child = new my_namespace::my_child();

  REQUIRE_EQUAL(child.getVal1(),1);
  REQUIRE_EQUAL(child.getVal2(),3);
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

END_TEST_SUITE()

END_TEST_PACKAGE()
