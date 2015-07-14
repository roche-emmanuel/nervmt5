/*
This is the version 2 of the Nerv EA.
This implementation will use the Bladerunner strategy as described from:
http://www.authenticfx.com/free-forex-trading-strategy.html
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

#include <nerv/core.mqh>
#include <nerv/expert/BladeRunnerTrader.mqh>

nvPeriodTrader* trader;

// Initialization method:
int OnInit()
{
  // Enable logging to file:
  nvLogManager* lm = nvLogManager::instance();
  string fname = "nerv_ea_v1.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  logDEBUG("Initializing Nerv EA.")
  nvSecurity sec("EURUSD",5,0.00001);
  trader = new BladeRunnerTrader(sec,PERIOD_H1);

  return 0;
}

// Uninitialization:
void OnDeinit(const int reason)
{
  logDEBUG("Uninitializing Nerv EA.")
  RELEASE_PTR(trader)
}

// OnTick handler:
void OnTick()
{
  trader.onTick();
}
