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

  // Initial start time:
  // Note: we should not start on the 1st of January:
  // Because there is no trading at that time!
  // datetime time = D'2015.01.05 00:00';
  // datetime time = D'2013.01.05 00:00';
  datetime time = D'2012.01.01 00:00';
  // datetime time = D'2010.01.01 00:00'; // dataset is not complete ?

  // Note that we must update the portfolio initial time **before**
  // adding the currency traders, otherwise, the first weight updated message
  // timetag could be largely different from the subsequent values.
  man.setCurrentTime(time);

  // Add some currency traders:
  int nsym = 4;
  string symbols[] = {"GBPJPY", "EURUSD", "EURJPY", "USDCHF"};
  // int nsym = 1;
  // string symbols[] = {"EURUSD"};

  nvDecisionComposerFactory* factory = man.getDecisionComposerFactory();

  for(int j=0;j<nsym;++j)
  {
    nvCurrencyTrader* ct = man.addCurrencyTrader(symbols[j]);
    // We have to stay on the virtual market only for the moment:
    ct.setMarketType(MARKET_TYPE_VIRTUAL);

    ct.setEntryDecisionComposer(factory.createEntryComposer(ct,DECISION_COMPOSER_MEAN));
    ct.setExitDecisionComposer(factory.createExitComposer(ct,DECISION_COMPOSER_MEAN));

    //nvIchimokuAgent* ichi = new nvIchimokuAgent(ct);
    nvIchimokuAgentB* ichi = new nvIchimokuAgentB(ct);
    ichi.setPeriod(PERIOD_H1);

    ct.addTradingAgent(GetPointer(ichi));
  }

  uint startTick = GetTickCount();
  int numDays=31*2;
  // int numDays=365*4;
  // int numDays = 31*4;
  int nsecs = 86400*numDays;
  int nmins = 26*60*numDays;
  for(int i=0;i<nmins;++i) {
    // logDEBUG("Elapsed time: "<<i);
    man.update(time+i*60);
  }

  uint endTick = GetTickCount();
  double elapsed = (double)(endTick-startTick)/1000.0;
  logDEBUG("Done executing portfolio test in "<< elapsed <<" seconds");
}
