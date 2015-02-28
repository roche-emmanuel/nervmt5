
#include <nerv/unit/Testing.mqh>
#include <nerv/trade/rrl/RRLCostFunction_SR.mqh>

BEGIN_TEST_PACKAGE(rrlcostfunction_specs)

BEGIN_TEST_SUITE("RRLCostFunction class")

BEGIN_TEST_CASE("should be able to create an RRLCostFunction")
  nvRRLTrainTraits ct; 
  nvVecd vec1(100);
  vec1.randomize(-1,1);
  ct.returns(vec1); 
  
  nvRRLCostFunction_SR costfunc(ct);
  
END_TEST_CASE()

BEGIN_TEST_CASE("should be able to assign and retrieve returns")
  nvRRLTrainTraits ct;  
  nvVecd vec1(10,1.0);
  nvVecd vec2(11,2.0);
  ct.returns(vec1).returns(vec2);

  REQUIRE_EQUAL(ct.returns(),vec2);
END_TEST_CASE()

BEGIN_TEST_CASE("should contain the same values on copy.")
  nvRRLTrainTraits ct;  
  nvVecd vec1(10,1.0);
  ct.returns(vec1);

  nvRRLTrainTraits ct2(ct);  

  // Note that we have to clone here to avoid comparing raw pointers
  // (which are not equals)
  REQUIRE_EQUAL(ct.returns(),ct2.returns().clone());
END_TEST_CASE()


BEGIN_TEST_CASE("should be able to compute a cost and gradient.")
  nvRRLTrainTraits ct;  
  nvVecd vec1(100);
  vec1.randomize(-1,1);
  ct.returns(vec1);

  nvRRLCostFunction costfunc(ct);

  nvVecd grad;
  nvVecd x(12,1.0);

  double cost = costfunc.sr_cost(x,grad);

  REQUIRE(cost!=0.0);
  REQUIRE_EQUAL(grad.size(),12);
  REQUIRE_GT(grad.norm(),0.0);
  REQUIRE_NOT_EQUAL(grad[0],0.0);
END_TEST_CASE()

BEGIN_TEST_CASE("should assign initial and final signal")
  nvRRLTrainTraits ct;  
  ct.initialSignal(1).finalSignal(2);

  REQUIRE_EQUAL(ct.useInitialSignal(),true);
  REQUIRE_EQUAL(ct.useFinalSignal(),false);
  REQUIRE_EQUAL(ct.initialSignal(),1);
  REQUIRE_EQUAL(ct.finalSignal(),2);
END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()
