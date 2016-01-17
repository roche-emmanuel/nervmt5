/*
This is the version 9 of the Nerv EA.
This implementation will use the Zone recovery trader
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

#include <nerv/core.mqh>
#include <nerv/expert/ZoneRecoveryTrader.mqh>

// input double   Price_Threshold=3.0;     // Price sigma multiplier to evaluate the entry threshold
// input double   MA_Threshold=1.3;     // MA sigma multiplier to evaluate the trend bubble entry
// input double   SL_Mult=1.0;     // Stoploss sigma multiplier used when placing a deal.
// input double   Slope_Threshold=2.0;     // Threshold multiplier in number of sigma for MA4 slope.
// input double   Risk_Decay=0.9;  // Decay factor for the risk aversion.

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
  nvSecurity sec("EURUSD");
  trader = new ZoneRecoveryTrader(sec,Period());

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
