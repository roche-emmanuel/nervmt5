
#include <nerv/unit/Testing.mqh>
#include <nerv/trades.mqh>

BEGIN_TEST_PACKAGE(trademodel_specs)

BEGIN_TEST_SUITE("TradeModel class")

BEGIN_TEST_CASE("should be able to create an TradeModel")
  nvTradeModelTraits traits; 
  nvTradeModel model(GetPointer(traits));
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
