/*
Test implementation based on portfolio test 03
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/expert/PortfolioManager.mqh>
#include <nerv/expert/agent/IchimokuAgent.mqh>

input int   gTimerPeriod=60;  // Timer period in seconds

nvPortfolioManager* portfolio = NULL;

// Initialization method:
int OnInit()
{
  // datetime time = D'2010.01.01 00:00';

  // int handle=iIchimoku("EURUSD",PERIOD_M1,9,26,52);
  // CHECK_RET(handle>0,0,"Invalid ichimoku handle.");
  // double vals[];
  // int num = CopyBuffer(handle,0,time,2,vals);
  // while(num<0) {
  //  logDEBUG("Waiting to get data...");
  //  Sleep(10);
  //  num = CopyBuffer(handle,0,time,2,vals);
  // } 
  
  // CHECK_RET(num==2,0,"Cannot copy buffer");

  logDEBUG("Initializing Nerv MultiCurrencyExpert.")

  nvLogManager* lm = nvLogManager::instance();
  string fname = "portfolio_ea_v01.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  logDEBUG("Initializing Portfolio test.");

  portfolio = new nvPortfolioManager();
  
  // Add some currency traders:
  // int nsym = 4;
  // string symbols[] = {"GBPJPY", "EURUSD", "EURJPY", "USDCHF"};
  int nsym = 1;
  // string symbols[] = {"EURUSD"};
  string symbols[] = {"GBPJPY"};

  nvDecisionComposerFactory* factory = portfolio.getDecisionComposerFactory();

  for(int j=0;j<nsym;++j)
  {
    nvCurrencyTrader* ct = portfolio.addCurrencyTrader(symbols[j]);
    // We have to stay on the virtual market only for the moment:
    ct.setMarketType(MARKET_TYPE_REAL);
    // ct.setMarketType(MARKET_TYPE_VIRTUAL);

    ct.setEntryDecisionComposer(factory.createEntryComposer(ct,DECISION_COMPOSER_MEAN));
    ct.setExitDecisionComposer(factory.createExitComposer(ct,DECISION_COMPOSER_MEAN));

    nvIchimokuAgent* ichi = new nvIchimokuAgent(ct);
    ichi.setPeriod(PERIOD_H1);

    ct.addTradingAgent(GetPointer(ichi));
  }
  
  portfolio.update(TimeCurrent());
  
  // Initialize the timer:
  CHECK_RET(EventSetTimer(gTimerPeriod),0,"Cannot initialize timer");
  return 0;
}

// Uninitialization:
void OnDeinit(const int reason)
{
  logDEBUG("Uninitializing Nerv MultiCurrencyExpert.")
  EventKillTimer();
  
  int npos = portfolio.getMarket(MARKET_TYPE_REAL).getPositiveDealCount();
  int nneg = portfolio.getMarket(MARKET_TYPE_REAL).getNegativeDealCount();
  logDEBUG("Positive deals: "<<npos<<", negative deals: "<<nneg);
  
  RELEASE_PTR(portfolio);
}

void OnTimer()
{
  portfolio.update(TimeCurrent());
}

