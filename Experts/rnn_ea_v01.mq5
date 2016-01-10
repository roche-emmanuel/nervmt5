/*
Implementation of RNN trader.

This trader will read the prediction data from a csv file
and then use those predictions to place orders.
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

// For EURUSD:
#property tester_file "eval_results_v36.csv"
#property tester_file "eval_results_v36b.csv"
#property tester_file "eval_results_v36c.csv"

#property tester_file "eval_results_v38.csv"
#property tester_file "eval_results_v38b.csv"
#property tester_file "eval_results_v38c.csv"

#property tester_file "eval_results_v42.csv"
#property tester_file "eval_results_v42b.csv"
#property tester_file "eval_results_v42c.csv"
#property tester_file "eval_results_v42d.csv"
#property tester_file "eval_results_v42e.csv"

#property tester_file "eval_results_v44.csv"
#property tester_file "eval_results_v44d.csv"

#property tester_file "eval_results_v45.csv"
#property tester_file "eval_results_v45b.csv"
#property tester_file "eval_results_v45c.csv"

#property tester_file "eval_results_v47.csv"
#property tester_file "eval_results_v47b.csv"
#property tester_file "eval_results_v47c.csv"

// For USDJPY:
#property tester_file "eval_results_v37.csv"
#property tester_file "eval_results_v37b.csv"
#property tester_file "eval_results_v37c.csv"

#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/rnn/RNNTrader.mqh>

input int   gTimerPeriod=1;  // Timer period in seconds

nvRNNTrader* rnntrader = NULL;

// Initialization method:
int OnInit()
{
  logDEBUG("Initializing Nerv RNN Expert.")

  nvLogManager* lm = nvLogManager::instance();
  string fname = "rnn_ea_v01.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);
  
  rnntrader = new nvRNNTrader();

  // Initialize the timer:
  CHECK_RET(EventSetTimer(gTimerPeriod),0,"Cannot initialize timer");
  return 0;
}

// Uninitialization:
void OnDeinit(const int reason)
{
  logDEBUG("Uninitializing Nerv RNN Expert.")
  EventKillTimer();

  // Destroy the trader:
  RELEASE_PTR(rnntrader);
}

// OnTick handler:
void OnTick()
{
  rnntrader.onTick();
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
  rnntrader.update(ctime);
}
