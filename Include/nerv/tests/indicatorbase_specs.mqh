
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/IndicatorBase.mqh>
#include <nerv/expert/indicators/Ichimoku.mqh>

BEGIN_TEST_PACKAGE(indicatorbase_specs)

BEGIN_TEST_SUITE("IndicatorBase class")

BEGIN_TEST_CASE("should be able to create an IndicatorBase instance")
	nvPortfolioManager man;
	nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
	
  nvIndicatorBase indicator(GetPointer(ct));
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to create an Ichimoku indicator")
  nvPortfolioManager man;
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  
  nviIchimoku ichi(GetPointer(ct),PERIOD_H1);
END_TEST_CASE()

BEGIN_TEST_CASE("Ichimoku indicator should produce the same result as the official indicator")

  nvPortfolioManager man;
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  
  nviIchimoku ichi(GetPointer(ct),PERIOD_M1);
  ichi.setParameters(9,26,52);
  int handle = iIchimoku("EURUSD",PERIOD_M1,9,26,52);

  datetime stime = D'2015.01.02 00:00';
  double vals[];

  int num = 1000;
  // int num = 1;
  datetime ctime;
  for(int i=0;i<num;++i) {
    ctime = stime + i*30;

    ichi.compute(ctime);

    ASSERT_EQUAL(CopyBuffer(handle,0,ctime,1,vals),1);
    ASSERT_EQUAL(ichi.getBuffer(ICHI_TENKAN),vals[0]);
    // logDEBUG("Tenkan value: "<<vals[0]);

    ASSERT_EQUAL(CopyBuffer(handle,1,ctime,1,vals),1);
    ASSERT_EQUAL(ichi.getBuffer(ICHI_KIJUN),vals[0]);
    // logDEBUG("Kijun value: "<<vals[0]);

    ASSERT_EQUAL(CopyBuffer(handle,2,ctime,1,vals),1);
    ASSERT_EQUAL(ichi.getBuffer(ICHI_SPAN_A),vals[0]);
    // logDEBUG("Span A legacy value: "<<vals[0]);
    // logDEBUG("Span A new value: "<<ichi.getBuffer(ICHI_SPAN_A));
    
    // ASSERT_EQUAL(CopyBuffer(handle,3,ctime,1,vals),1);
    // ASSERT_EQUAL(ichi.getBuffer(ICHI_SPAN_B),vals[0]);
  }





  // ASSERT_EQUAL(CopyBuffer(handle,4,stime,1,vals),1);
  // ASSERT_EQUAL(ichi.getBuffer(ICHI_CHINKOU),vals[0]);

  // int count = 10;
  // for(int i=0;i<count;++i) {
  // }

END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
