
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trades.mqh>
#include <nerv/trade/Strategy.mqh>
#include <nerv/trade/rrl/RRLCostFunction_SR.mqh>

BEGIN_TEST_PACKAGE(costfunc_SR_specs)

BEGIN_TEST_SUITE("CostFunction SR evaluation")

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

END_TEST_SUITE()

END_TEST_PACKAGE()
