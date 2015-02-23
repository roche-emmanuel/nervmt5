
#include <nerv/unit/Testing.mqh>
#include <nerv/trade/rrl/RRLModel.mqh>

BEGIN_TEST_PACKAGE(rrlmodel_specs)

BEGIN_TEST_SUITE("RRLModelBase class")

BEGIN_TEST_CASE("should be able to create an RRLModel")
  nvRRLModelTraits traits; 
  nvRRLModel model(traits);
END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()
