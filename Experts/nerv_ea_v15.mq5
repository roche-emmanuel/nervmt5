/*
Implementation of a pattern trader

This trader will build patterns from the input ticks/bar data
and compare the current pattern against the history to decide 
if we should enter a trade.
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

#property strict

//#include <stdlib.mqh>
#include <nerv/core.mqh>
#include <nerv/trading/PatternTrader.mqh>


input bool gUseTicks = true; // Specify if we should use tick data or bar data
input int  gInputSize = 1; // The input packet size to consider


nvPatternTrader* ptrader = NULL;

// Initialization method:
int OnInit()
{    
  logDEBUG("Initializing Nerv Pattern trader.")

  nvLogManager* lm = nvLogManager::instance();
  string fname = "nerv_ea_v15.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  ptrader = new nvPatternTrader(Symbol(),gUseTicks,gInputSize);

  return 0;
}

// Uninitialization:
void OnDeinit(const int reason)
{
  logDEBUG("Uninitializing Nerv Pattern Expert.")

  // Destroy the trader:
  RELEASE_PTR(ptrader);
}

// OnTick handler:
void OnTick()
{
  MqlTick tick;
  CHECK(SymbolInfoTick(Symbol(),tick),"Cannot retrieve the latest tick");

  ptrader.onTick(tick.time, (tick.bid+tick.ask)*0.5);
}
