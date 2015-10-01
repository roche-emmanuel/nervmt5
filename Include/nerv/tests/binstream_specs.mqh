
#include <nerv/unit/Testing.mqh>
#include <nerv/network/BinStream.mqh>

BEGIN_TEST_PACKAGE(binstream_specs)

BEGIN_TEST_SUITE("BinStream class")

BEGIN_TEST_CASE("Should be able to create a simple object")
  nvBinStream stream;

	ASSERT_EQUAL(stream.size(),0);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to read/write a string")
  nvBinStream stream;

  string str = "Hello world";
  stream << str;

  // Should write 4 bytes for the string length:
  ASSERT_EQUAL(stream.size(),11+4);

  uchar data[];
  stream.getBuffer(data);
  ASSERT_EQUAL((int)data[0],11);
  ASSERT_EQUAL((int)data[1],0);
  ASSERT_EQUAL((int)data[2],0);
  ASSERT_EQUAL((int)data[3],0);
  ASSERT_EQUAL((int)data[4],(int)'H');

  string str2;
  stream.resetPos();
  stream >> str2;
  ASSERT_EQUAL(str,str2);

END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to read/write an int")
  nvBinStream stream;

  int val = 42;

  stream << val;

  ASSERT_EQUAL(stream.size(),4);

  uchar data[];
  stream.getBuffer(data);
  ASSERT_EQUAL((int)data[0],42);
  ASSERT_EQUAL((int)data[1],0);
  ASSERT_EQUAL((int)data[2],0);
  ASSERT_EQUAL((int)data[3],0);

  int32_stream st;
  ArrayFill(st.data,0,4,0);

  // copy the data in the int32_st array:
  ArrayCopy( st.data, data, 0, 0, 4 );

  int arr[];
  ArrayResize( arr, 1 );
  arr[0] = 50;

  long src = getMemAddress(st.data);
  long dest = getMemAddress(arr);

  memcpy(dest,src,4);
  
  ASSERT_EQUAL(arr[0],val);


  stream.resetPos();

  int val2;
  stream >> val2;
  ASSERT_EQUAL(val,val2);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to read/write a double")
  nvBinStream stream;

  double val = 12.34;

  stream << val;

  ASSERT_EQUAL(stream.size(),8);

  stream.resetPos();

  double val2;
  stream >> val2;
  ASSERT_EQUAL(val,val2);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to read/write multiple elements")
  nvBinStream stream;

  int ival = 123;
  double dval = 12.34;
  string str = "Hello";

  stream << ival << dval << str;

  ASSERT_EQUAL(stream.size(),21);

  stream.resetPos();

  int ival2;
  double dval2;
  string str2;

  stream >> ival2 >> dval2 >> str2;

  ASSERT_EQUAL(ival,ival2);
  ASSERT_EQUAL(dval,dval2);
  ASSERT_EQUAL(str,str2);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to read/write a bool or char")
  nvBinStream stream;

  bool bval1 = true;
  bool bval2 = false;
  char cval = (char)128;

  stream << bval1 << cval << bval2;

  ASSERT_EQUAL(stream.size(),3);

  stream.resetPos();

  bool rbval1, rbval2;
  char rcval;

  stream >> rbval1 >> rcval >> rbval2;
  ASSERT_EQUAL(bval1,rbval1);
  ASSERT_EQUAL(bval2,rbval2);
  ASSERT_EQUAL((int)cval,(int)rcval);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to read/write a short")
  nvBinStream stream;

  short val1 = 12345;
  short val2 = 12346;

  stream << val1 << val2;

  ASSERT_EQUAL(stream.size(),4);

  stream.resetPos();

  short rval1, rval2;
  stream >> rval1 >> rval2;
  ASSERT_EQUAL(val1,rval1);
  ASSERT_EQUAL(val2,rval2);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to read/write a ushort")
  nvBinStream stream;

  ushort val1 = 32345;
  ushort val2 = 62346;

  stream << val1 << val2;

  ASSERT_EQUAL(stream.size(),4);

  stream.resetPos();

  ushort rval1, rval2;
  stream >> rval1 >> rval2;
  ASSERT_EQUAL(val1,rval1);
  ASSERT_EQUAL(val2,rval2);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to read/write a uchar")
  nvBinStream stream;

  uchar val1 = 240;
  uchar val2 = 255;

  stream << val1 << val2;

  ASSERT_EQUAL(stream.size(),2);

  stream.resetPos();

  uchar rval1, rval2;
  stream >> rval1 >> rval2;
  ASSERT_EQUAL(val1,rval1);
  ASSERT_EQUAL(val2,rval2);
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to read/write a datetime")
  nvBinStream stream;

  datetime t = TimeLocal();

  stream << t;

  ASSERT_EQUAL(stream.size(),9);

  stream.resetPos();

  datetime t2;
  stream >> t2;
  ASSERT_EQUAL(t,t2);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
