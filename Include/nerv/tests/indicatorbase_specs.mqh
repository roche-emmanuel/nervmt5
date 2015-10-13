
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
  ichi.setHistorySize(26);

  int handle = iIchimoku("EURUSD",PERIOD_M1,9,26,52);

  datetime stime = D'2015.01.02 00:00';
  double vals[];
  //double val;
  MqlRates rates[];

  int num = 1000;
  // int num = 1;
  datetime ctime;
  for(int i=0;i<num;++i) {
    ctime = stime + i*30;

    ichi.compute(ctime);

    ASSERT_EQUAL(CopyBuffer(handle,0,ctime,1,vals),1);
    ASSERT_EQUAL(ichi.getBuffer(ICHI_TENKAN),vals[0]);

    ASSERT_EQUAL(CopyBuffer(handle,1,ctime,1,vals),1);
    ASSERT_EQUAL(ichi.getBuffer(ICHI_KIJUN),vals[0]);

    ASSERT_EQUAL(CopyBuffer(handle,2,ctime,1,vals),1);
    ASSERT_EQUAL(ichi.getBuffer(ICHI_SPAN_A),vals[0]);
    
    ASSERT_EQUAL(CopyBuffer(handle,3,ctime,1,vals),1);
    ASSERT_EQUAL(ichi.getBuffer(ICHI_SPAN_B),vals[0]);

    // Note: no clear idea on how to test the chinkou line for now:
    // legacy ichimoku indicator doesn't seem to match the data.

    // The chinkou line is plotted **back** in time...
    // Which mean that we cannot compute its value at a given
    // time: instead we should retrieve the historical data:
    // ichi.compute(ctime-26*60);

    ASSERT_EQUAL(CopyRates("EURUSD",PERIOD_M1,ctime,1,rates),1);
    ASSERT_EQUAL(ichi.getBuffer(ICHI_CHINKOU),rates[0].close);
    // ASSERT_EQUAL(CopyBuffer(handle,4,ctime,1,vals),1);
    // ASSERT_EQUAL(rates[0].close,vals[0])
    // ASSERT_EQUAL(ichi.getBuffer(ICHI_CHINKOU),vals[0]);


    // if(ichi.getBuffer(ICHI_CHINKOU,26,val)) {
    //   // logDEBUG("Comparing Chinkou buffer!")
    //   ASSERT_EQUAL(CopyBuffer(handle,4,ctime-26*60,1,vals),1);
    //   ASSERT_EQUAL(val,vals[0]);  
    //   // Value in the future:
    //   // ASSERT_EQUAL(CopyRates("EURUSD",PERIOD_M1,ctime+26*60,1,rates),1);
    //   ASSERT_EQUAL(CopyRates("EURUSD",PERIOD_M1,ctime,1,rates),1);
    //   ASSERT_EQUAL(rates[0].close,vals[0])
    //   // logDEBUG("Future value is: " << rates[0].close);
    // }
  }

END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to retrieve data far in the past from Ichimoku indicator")
  datetime time = D'2010.01.01 00:00';

  int handle=iIchimoku("EURUSD",PERIOD_M1,9,26,52);
  ASSERT(handle>0);
  double vals[];
  ASSERT_EQUAL(CopyBuffer(handle,0,time,2,vals),2);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
