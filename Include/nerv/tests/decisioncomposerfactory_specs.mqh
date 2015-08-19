
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/DecisionComposerFactory.mqh>

BEGIN_TEST_PACKAGE(decisioncomposerfactory_specs)

BEGIN_TEST_SUITE("DecisionComposerFactory class")

BEGIN_TEST_CASE("should be able to create a DecisionComposerFactory instance")
	nvDecisionComposerFactory factory;
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide the current count of entry decision composer")
  nvPortfolioManager man;
  nvDecisionComposerFactory* factory = man.getDecisionComposerFactory();

  int num = factory.getEntryTypeCount();
  ASSERT_EQUAL(num,1);
  
  
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  
  for(int i=0;i<num;++i)
  {
    nvDecisionComposer* comp = factory.createEntryComposer(ct,i);
    ASSERT_NOT_NULL(comp);
    RELEASE_PTR(comp);
  }
  
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide the current count of exit decision composer")
  nvPortfolioManager man;
  nvDecisionComposerFactory* factory = man.getDecisionComposerFactory();

  int num = factory.getExitTypeCount();
  ASSERT_EQUAL(num,1);
  
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  
  for(int i=0;i<num;++i)
  {
    nvDecisionComposer* comp = factory.createExitComposer(ct,i);
    ASSERT_NOT_NULL(comp);
    RELEASE_PTR(comp);
  }
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
