/*
Implementation of RNN trader.

This trader will read the prediction data from a csv file
and then use those predictions to place orders.
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>

input int   gTimerPeriod=60;  // Timer period in seconds

nvPortfolioManager* portfolio = NULL;

// Initialization method:
int OnInit()
{
  logDEBUG("Initializing Nerv RNN Expert.")

  nvLogManager* lm = nvLogManager::instance();
  string fname = "rnn_ea_v01.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  logDEBUG("Initializing Portfolio test.");

  portfolio = new nvPortfolioManager();
  
  // Add some currency traders:
  // int nsym = 4;
  // string symbols[] = {"GBPJPY", "EURUSD", "EURJPY", "USDCHF"};
  int nsym = 1;
  string symbols[] = {"EURUSD"};
  // string symbols[] = {"GBPJPY"};

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
  
  // Ensure that we always use the same seed here:
  portfolio.getRandomGenerator().SetSeed(123);

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

