
#include <nerv/unit/Testing.mqh>
#include <nerv/math.mqh>

BEGIN_TEST_PACKAGE(math_specs)

BEGIN_TEST_SUITE("Math components")

BEGIN_TEST_SUITE("Vecd class")

BEGIN_TEST_CASE("should be able to create a vector")
  int len = 10;
  nvVecd vec(len);
  REQUIRE_EQUAL_MSG(vec.size(),len,"Invalid vector length");
END_TEST_CASE()

BEGIN_TEST_CASE("should use default provided value and implemente operator[]")
  int len = 10;
  double val = nv_random_real();
  //MESSAGE("Initial value is: "+(string)val);

  nvVecd vec(len,val);
  for(int i=0;i<len;++i) {
    REQUIRE_EQUAL(vec[i],val);
  }
END_TEST_CASE()

BEGIN_TEST_CASE("should support setting element value")
  int len = 10;
  double val = 1.0;
  nvVecd vec(len,val);

  REQUIRE_EQUAL(vec[0],val);
  vec.set(0,1.0);
  REQUIRE_EQUAL(vec.get(0),1.0);
END_TEST_CASE()

BEGIN_TEST_CASE("should have equality operator")
  int len = 10;
  double val = 1.0;
  nvVecd vec1(len,val);
  nvVecd vec2(len,val);

  REQUIRE(vec1==vec2);
  vec2.set(1,val+1.0);
  REQUIRE(vec1!=vec2);
END_TEST_CASE()

BEGIN_TEST_CASE("should have operator+")
  int len = 10;
  nvVecd vec1(len,1.0);
  nvVecd vec2(len,2.0);
  nvVecd vec3(len,3.0);

  REQUIRE(vec1+vec2==vec3);
END_TEST_CASE()

BEGIN_TEST_CASE("should have operator*")
  int len = 10;
  nvVecd vec1(len,1.0);
  nvVecd vec2(len,2.0);

  REQUIRE(vec1*2==vec2);
END_TEST_CASE()

BEGIN_TEST_CASE("should support construction from array")
  double arr[] = {1,2,3,4,5};
  nvVecd vec1(arr);

  REQUIRE(vec1.size()==5);
  REQUIRE(vec1[3]==4);
END_TEST_CASE()

BEGIN_TEST_CASE("should support push_back method")
  double arr[] = {1,2,3,4,5};
  double arr2[] = {2,3,4,5,6};
  nvVecd vec1(arr);
  nvVecd vec2(arr2);

  double val = vec1.push_back(6);
  REQUIRE(vec1==vec2);
  REQUIRE(val==1.0);
END_TEST_CASE()

BEGIN_TEST_CASE("should support push_front method")
  double arr[] = {1,2,3,4,5};
  double arr2[] = {6,1,2,3,4};
  nvVecd vec1(arr);
  nvVecd vec2(arr2);

  double val = vec1.push_front(6);
  REQUIRE(vec1==vec2);
  REQUIRE(val==5.0);
END_TEST_CASE()

BEGIN_TEST_CASE("should support toString method")
  double arr[] = {1,2,3,4,5};
  nvVecd vec1(arr);
  
  REQUIRE_EQUAL(vec1.toString(),"Vecd(1,2,3,4,5)");
  DISPLAY(vec1);
  //string str = vec1<<"Vec is: ";
  //REQUIRE_EQUAL(str,"Vec is: Vecd(1,2,3,4,5)");
END_TEST_CASE()

BEGIN_TEST_CASE("should have assignment operator")
  double arr[] = {1,2,3,4,5};
  nvVecd vec1(arr);

  nvVecd vec2(5);
  vec2 = vec1;
  
  REQUIRE_EQUAL(vec2.size(),5);
  REQUIRE(vec1==vec2);
END_TEST_CASE()

BEGIN_TEST_CASE("should have operator-")
  int len = nv_random_int(1,100);
  nvVecd vec1(len,1.0);
  nvVecd vec2(len,2.0);
  nvVecd vec3(len,3.0);

  REQUIRE(vec3-vec2==vec1);
END_TEST_CASE()

BEGIN_TEST_CASE("should have unary operator-")
  int len = nv_random_int(1,100);
  nvVecd vec1(len,1.0);
  nvVecd vec2(len,-1.0);

  REQUIRE(-vec2==vec1);
END_TEST_CASE()

BEGIN_TEST_CASE("should support dot product")
  int len = nv_random_int(1,100);
  nvVecd vec1(len,2.0);
  nvVecd vec2(len,3.0);

  REQUIRE_EQUAL(vec1*vec2,(len*6.0));
END_TEST_CASE()

BEGIN_TEST_CASE("should support norm computation")
  int len = nv_random_int(1,100);
  nvVecd vec1(len,2.0);

  REQUIRE_EQUAL(vec1.norm2(),(len*4.0));
  REQUIRE_EQUAL(vec1.norm(),MathSqrt(len*4.0));
END_TEST_CASE()

BEGIN_TEST_CASE("should support operator/")
  int len = nv_random_int(1,100);
  nvVecd vec1(len,2.0);
  nvVecd vec2(len,1.0);

  nvVecd vec3 = vec1/2.0;
  REQUIRE(vec3==vec2);
END_TEST_CASE()

BEGIN_TEST_CASE("should support renormalization")
  int len = nv_random_int(1,100);
  nvVecd vec1(len,2.0);

  double val = vec1.normalize();
  REQUIRE_CLOSE(vec1.norm(),1.0,1e-6);
  REQUIRE_EQUAL(val,MathSqrt(len*4.0));
END_TEST_CASE()

BEGIN_TEST_CASE("should support back and front access")
  double arr[] = {1,2,3,4,5};
  nvVecd vec1(arr);
  
  REQUIRE_EQUAL(vec1.front(),1);
  REQUIRE_EQUAL(vec1.back(),5);
END_TEST_CASE()

BEGIN_TEST_CASE("should support randomization function")
  int len = nv_random_int(1,100);
  nvVecd vec1(len);
  
  vec1.randomize(-1.0,1.0);

  for(int i=0;i<len-1;++i) {
    REQUIRE_NOT_EQUAL(vec1[i],vec1[i+1]);
  }
END_TEST_CASE()

BEGIN_TEST_CASE("should support sub vector setting")
  double arr1[] = {1,2,3,4,5,6,7,8,9,10};
  double arr2[] = {3,2,1};
  double arr3[] = {1,2,3,3,2,1,7,8,9,10};
  nvVecd vec1(arr1);
  nvVecd vec2(arr2);
  nvVecd vec3(arr3);
  
  vec1.set(3,vec2);

  REQUIRE_EQUAL(vec1,vec3);
END_TEST_CASE()

BEGIN_TEST_CASE("should support retrieving min and max values")
  double arr1[] = {3,2,1,4,5,6,7,8,10,9};
  nvVecd vec1(arr1);

  REQUIRE_EQUAL(vec1.min(),1);
  REQUIRE_EQUAL(vec1.max(),10);
END_TEST_CASE()

BEGIN_TEST_CASE("should support computing mean value")
  double arr1[] = {1,2,3,4,5,6,7,8,9};
  nvVecd vec1(arr1);

  REQUIRE_EQUAL(vec1.mean(),5);
  REQUIRE(vec1.deviation()>0);
END_TEST_CASE()

BEGIN_TEST_CASE("should support creating dynamic vectors")
  nvVecd vec1;

  REQUIRE_EQUAL(vec1.size(),0);
  vec1.push_back(1.1);
  REQUIRE_EQUAL(vec1.size(),1);
  REQUIRE_EQUAL(vec1[0],1.1);
  vec1.push_front(2.2);
  REQUIRE_EQUAL(vec1.size(),2);
  REQUIRE_EQUAL(vec1[0],2.2);
  REQUIRE_EQUAL(vec1[1],1.1);
END_TEST_CASE()

BEGIN_TEST_CASE("should support popping values")
  double arr1[] = {1,2,3,4,5,6,7,8,9};
  nvVecd vec1(arr1,true);

  REQUIRE_EQUAL(vec1.size(),9);
  REQUIRE_EQUAL(vec1.pop_front(),1);
  REQUIRE_EQUAL(vec1.pop_back(),9);
  REQUIRE_EQUAL(vec1.pop_front(),2);
  REQUIRE_EQUAL(vec1.pop_back(),8);
  REQUIRE_EQUAL(vec1.size(),5);
  REQUIRE_EQUAL(vec1[0],3);
END_TEST_CASE()

BEGIN_TEST_CASE("should support computation of EMA")
  double arr1[] = {1,2,3,4,5,6,7,8,9};
  nvVecd vec1(arr1);

  REQUIRE(vec1.EMA(0.9)>vec1.EMA(0.8));
END_TEST_CASE()

BEGIN_TEST_CASE("should support adding/substracting scalar")
  double arr1[] = {1,2,3,4,5,6,7,8,9};
  nvVecd vec1(arr1);

  vec1 = vec1 + 1;
  REQUIRE_EQUAL(vec1[0],2);

  vec1 -= 2.0;
  REQUIRE_EQUAL(vec1[0],0.0);
END_TEST_CASE()

BEGIN_TEST_CASE("should support retrieving sub vector")
  double arr1[] = {1,2,3,4,5,6,7,8,9};
  nvVecd vec1(arr1);

  nvVecd vec2 = vec1.subvec(1,3);

  REQUIRE_EQUAL(vec2.size(),3);
  REQUIRE_EQUAL(vec2[0],2);
  REQUIRE_EQUAL(vec2[1],3);
  REQUIRE_EQUAL(vec2[2],4);
END_TEST_CASE()

BEGIN_TEST_CASE("should support reading vector from file")
  nvVecd vec1 = nv_read_vecd("retDAX.txt");

  REQUIRE_EQUAL(vec1.size(),5425);

  // Check the mean and deviation values:
  REQUIRE_CLOSE(vec1.mean(),-0.0001670546824234,1e-6);
  REQUIRE_CLOSE(vec1.deviation(),0.0147594082452264,1e-6);
END_TEST_CASE()

BEGIN_TEST_CASE("should support performing std normalization")
  nvVecd vec1 = nv_read_vecd("retDAX.txt");

  REQUIRE_EQUAL(vec1.size(),5425);

  nvVecd vec2 = vec1.stdnormalize();

  nvVecd diff = vec2 - (vec1 - vec1.mean())/vec1.deviation();

  // Check the mean and deviation values:
  REQUIRE_CLOSE(diff.norm(),0.0,1e-6);
END_TEST_CASE()

BEGIN_TEST_CASE("should support per element multiplication")
  double arr1[] = {1,2,3,4,5};
  double arr2[] = {5,4,3,2,1};
  double arr3[] = {5,8,9,8,5};
  nvVecd vec1(arr1);
  nvVecd vec2(arr2);
  nvVecd vec3(arr3);

  REQUIRE_EQUAL(vec1.mult(vec2),vec3);
END_TEST_CASE()

BEGIN_TEST_CASE("should support copying to array")
  double arr1[] = {1,2,3,4,5};
  double arr2[];
  nvVecd vec1(arr1);
  
  vec1.toArray(arr2);

  REQUIRE_EQUAL(arr2[4],vec1[4]);
END_TEST_CASE()

BEGIN_TEST_CASE("should support assignment from array")
  double arr1[] = {1,2,3,4,5};
  
  nvVecd vec1;
  
  vec1 = arr1;
  REQUIRE_EQUAL(arr1[4],vec1[4]);
  
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_SUITE()

END_TEST_PACKAGE()
