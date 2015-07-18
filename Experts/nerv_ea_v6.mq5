/*
This is the version 6 of the Nerv EA.
This implementation will use the Peak trader
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

#include <nerv/core.mqh>
#include <nerv/expert/PeakTrader.mqh>

input double   Price_Threshold=3.0;     // Price sigma multiplier to evaluate the entry threshold
input double   MA_Threshold=1.3;     // MA sigma multiplier to evaluate the trend bubble entry
input double   SL_Mult=2.0;     // Stoploss sigma multiplier used when placing a deal.
input double   Slope_Threshold=1.0;     // Threshold multiplier in number of sigma for MA4 slope.

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
  trader = new PeakTrader(sec,Period(),Price_Threshold,MA_Threshold,SL_Mult,Slope_Threshold);

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
