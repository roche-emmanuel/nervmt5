/*
Implementation of a "English Breakfast Tea" strategy from "17 Proven Currency Trading Strategies"

Initial rationale:

When  the GBP/USD trends  in  one direction from  04:15 hours to  08:30 hours London  time, 
it  has a tendency  to  move  in  the other direction after 08:30 hours.
Hence,  we  first compare the closing price of  the 15-minute (M15) candle  that  corresponds to  04:15
hours and 08:15 hours London  time  to  determine the direction of  the GBP/USD.  We  then  enter a trade in
the opposite  direction at  08:30 hours London  time.
As  an  example,  if  the closing price of  the M15 candle  at  08:15 hours is  lower than  the closing price at
04:15 hours,  we  go  long  at  08:30 hours.  If  the closing price of  the M15 candle  at  08:15 hours is  higher
than  the closing price at  04:15 hours,  we  go  short at  08:30 hours.
The stop  loss  is  fixed at  30  pips, and there are three profit  targets for this  strategy  with  risk  to  reward
ratios   of  1:1,  1:2,  and   1:3.  In  other   words,  the   profit  targets   are   30  pips,   60  pips,   and   90  pips
respectively.
*/

#property copyright "Copyright 2016, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

#property strict

//#include <stdlib.mqh>
#include <nerv/core.mqh>
#include <nerv/trading/BreakfastTeaTrader.mqh>


input int StartTime = 4*60; // Start time in minutes
input int EvalTime = 8*60 + 45; // Eval time in minutes
input int StopLoss = 130; // StopLoss in num points
input int TakeProfit = 350; // Takeprofit in num points


nvBreakfastTeaTrader* btrader = NULL;

// Initialization method:
int OnInit()
{    
  logDEBUG("Initializing Nerv BreakfastTeaTrader trader.")

  nvLogManager* lm = nvLogManager::instance();
  string fname = "nerv_ea_v16.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  btrader = new nvBreakfastTeaTrader(Symbol(), StartTime, EvalTime);
  btrader.setStopLossPoints(StopLoss);
  btrader.setTakeProfitPoints(TakeProfit);

  return 0;
}

// Uninitialization:
void OnDeinit(const int reason)
{
  logDEBUG("Uninitializing Nerv BreakfastTea Expert.")

  // Destroy the trader:
  RELEASE_PTR(btrader);
}

// OnTick handler:
void OnTick()
{
  btrader.onTick();
}
