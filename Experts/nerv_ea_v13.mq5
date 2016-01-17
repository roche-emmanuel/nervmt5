/*
Implementation of Multi trader.

This trader will read the prediction data from a csv file
and then use those predictions to place orders.
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trading/MultiTrader.mqh>
#include <nerv/trading/MATrader.mqh>
#include <nerv/trading/ZoneRecoveryTrader.mqh>

input int   gTimerPeriod=60;  // Timer period in seconds

nvMultiTrader* mtrader = NULL;

// Initialization method:
int OnInit()
{
  logDEBUG("Initializing Nerv Multi Expert.")

  nvLogManager* lm = nvLogManager::instance();
  string fname = "nerv_ea_v13.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);
  
  mtrader = new nvMultiTrader();

  // mtrader.addTrader(new nvMATrader("EURUSD"));
  mtrader.addTrader(new nvZoneRecoveryTrader("EURUSD",PERIOD_D1,PERIOD_M5,PERIOD_H4,PERIOD_H1,PERIOD_M5,PERIOD_M15,PERIOD_M30,PERIOD_H1));
  // mtrader.addTrader(new nvZoneRecoveryTrader("GBPUSD",PERIOD_D1,PERIOD_M15,PERIOD_H4,PERIOD_H1,PERIOD_M15));

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
  mtrader.onTick();
}

void OnTimer()
{
  // We call the timer every second because we don't know if we are
  // on sec 0, and this is what we should compute here:
  datetime ctime = TimeCurrent();
  MqlDateTime dts;
  TimeToStruct(ctime,dts);

  // Zero the number of seconds:
  ctime = ctime - dts.sec;

  // Sent to the trader to see if an update cycle is required:
  mtrader.update(ctime);
}
