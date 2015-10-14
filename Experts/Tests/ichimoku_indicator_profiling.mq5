// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/expert/PortfolioManager.mqh>
#include <nerv/expert/agent/IchimokuAgent.mqh>
#include <nerv/expert/agent/IchimokuAgentB.mqh>

void OnStart()
{
  nvLogManager* lm = nvLogManager::instance();
  string fname = "portfolio_test_03.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  logDEBUG("Initializing Portfolio test.");

  nvPortfolioManager man;
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  
  nviIchimoku ichi(GetPointer(ct),PERIOD_H1);
  ichi.setParameters(9,26,52);

  int handle = iIchimoku("EURUSD",PERIOD_H1,9,26,52);

  datetime stime = D'2015.01.02 00:00';
  double vals[];
  //double val;
  MqlRates rates[];

  int num = 5000;
  // int num = 1;
  datetime ctime;
  for(int i=0;i<num;++i) {
    ctime = stime + i*60;

    ichi.compute(ctime);

    CHECK(CopyBuffer(handle,0,ctime,1,vals)==1,"Invalid result");
    CHECK(ichi.getBuffer(ICHI_TENKAN)==vals[0],"Invalid result");

    CHECK(CopyBuffer(handle,1,ctime,1,vals)==1,"Invalid result");
    CHECK(ichi.getBuffer(ICHI_KIJUN)==vals[0],"Invalid result");

    CHECK(CopyBuffer(handle,2,ctime,1,vals)==1,"Invalid result");
    CHECK(ichi.getBuffer(ICHI_SPAN_A)==vals[0],"Invalid result");
    
    CHECK(CopyBuffer(handle,3,ctime,1,vals)==1,"Invalid result");
    CHECK(ichi.getBuffer(ICHI_SPAN_B)==vals[0],"Invalid result");

    CHECK(CopyRates("EURUSD",PERIOD_H1,ctime,1,rates)==1,"Invalid result");
    CHECK(ichi.getBuffer(ICHI_CHINKOU)==rates[0].close,"Invalid result");    
  }

  logDEBUG("Done executing portfolio test.");
}
