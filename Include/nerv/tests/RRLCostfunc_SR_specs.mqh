
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trades.mqh>
#include <nerv/trade/Strategy.mqh>
#include <nerv/trade/rrl/RRLCostFunction_SR.mqh>

BEGIN_TEST_PACKAGE(costfunc_SR_specs)

BEGIN_TEST_SUITE("CostFunction SR")

BEGIN_TEST_CASE("should support computing cost")
  nvRRLModelTraits traits;

  nvVecd returns(1000);
  returns.randomize(0.0,2.0);

  nvRRLCostFunction_SR costfunc(traits,returns);

  nvVecd xvec(traits.numInputReturns()+2,1.0);
  nvVecd grad;

  double cost = costfunc.computeCost(xvec,grad);

  REQUIRE_NOT_EQUAL(cost,0.0);
  REQUIRE_GT(grad.norm(),0.0);
END_TEST_CASE()

BEGIN_TEST_CASE("should provide correct gradient")
  int num = 10;
  for(int i=0;i<num;++i)
  {
    MESSAGE("Checking numerical gradients "<<i<<"...");

    nvRRLModelTraits traits;
    traits.numInputReturns(nv_random_int(10,10));
    traits.lambda(nv_random_real(0.0001,0.01));
    nvVecd returns(500);
    returns.randomize(1.0,1.4);

    nvRRLCostFunction_SR costfunc(traits,returns);

    nvVecd xvec(traits.numInputReturns()+2,1.0);
    xvec.randomize(-1.0,1.0);
    nvVecd grad;

    costfunc.computeCost(xvec,grad);
    
    nvVecd ngrad;
    costfunc.computeNumericalGradient(xvec,ngrad,1e-6);

    double diff = (ngrad-grad).norm()/(ngrad+grad).norm();
    // nvVecd rdiff = (grad-ngrad).abs().div(grad);
    // DISPLAY(grad);
    // DISPLAY(ngrad);
    // REQUIRE_LT(rdiff.max(),1e-11)
    REQUIRE_LT(diff,1e-7)
  }
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
