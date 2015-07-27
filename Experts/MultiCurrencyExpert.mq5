/*
This is the version 11 of the Nerv EA.
This implementation will use the Heiken Ashi trader
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

input int   gTimerPeriod=1;  // Timer period in seconds

#include <nerv/core.mqh>

// Initialization method:
int OnInit()
{
  // Enable logging to file:
  nvLogManager* lm = nvLogManager::instance();
  string fname = "nerv_multi_currency_expert_v1.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  logDEBUG("Initializing Nerv MultiCurrencyExpert.")

  // Initialize the timer:
  CHECK(EventSetTimer(gTimerPeriod),"Cannot initialize timer");
  return 0;
}

// Uninitialization:
void OnDeinit(const int reason)
{
  logDEBUG("Uninitializing Nerv MultiCurrencyExpert.")
  EventKillTimer();
}

void OnTimer()
{
  // logDEBUG(TimeCurrent()<<": OnTimer() called.")
  logDEBUG(TimeLocal()<<": OnTimer() called.")
}

