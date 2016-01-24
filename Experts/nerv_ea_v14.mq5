/*
Implementation of Multi trader.

This trader will read the prediction data from a csv file
and then use those predictions to place orders.
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

//#include <stdlib.mqh>
#include <nerv/core.mqh>
#include <nerv/trading/MultiTrader.mqh>
#include <nerv/trading/RandomTrader.mqh>
#include <nerv/trading/HATrader.mqh>
#include <nerv/trading/HATraderV2.mqh>
#include <nerv/trading/HATraderV3.mqh>

// #include <nerv/trading/RandomALRTrader.mqh>
// #include <nerv/trading/HAZRTrader.mqh>
// #include <nerv/trading/ScalperTrader.mqh>

// #define USE_TIMER

input int   gTimerPeriod=1;  // Timer period in seconds

nvMultiTrader* mtrader = NULL;

// Initialization method:
int OnInit()
{    
  logDEBUG("Initializing Nerv Multi Expert.")

  nvLogManager* lm = nvLogManager::instance();
  string fname = "nerv_ea_v14.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  mtrader = new nvMultiTrader((ENUM_TIMEFRAMES)Period());

  // add a random trader:
  // mtrader.addTrader(new nvRandomTrader("EURUSD"));
  // mtrader.addTrader(new nvHATrader("EURUSD"));
  // mtrader.addTrader(new nvHATraderV2("EURUSD"));
  mtrader.addTrader(new nvHATraderV3("EURUSD"));
  // mtrader.addTrader(new nvHATraderV3("EURJPY"));
  // mtrader.addTrader(new nvHATraderV3("USDJPY"));

  // mtrader.addTrader(new nvRandomALRTrader("EURUSD"));
  // mtrader.addTrader(new nvRandomALRTrader("USDJPY"));
  // mtrader.addTrader(new nvScalperTrader("EURUSD"));
  // mtrader.addTrader(new nvHAZRTrader("EURUSD"));
  // mtrader.addTrader(new nvHAZRTrader("USDJPY"));

  // Initialize the timer:
  CHECK_RET(EventSetTimer(gTimerPeriod),0,"Cannot initialize timer");

  return 0;
}

// Uninitialization:
void OnDeinit(const int reason)
{
  logDEBUG("Uninitializing Nerv Multi Expert.")
  EventKillTimer();

  // Destroy the trader:
  RELEASE_PTR(mtrader);
}

// OnTick handler:
void OnTick()
{
  mtrader.update();
  mtrader.onTick();
}

void OnTimer()
{
  mtrader.update();
}
