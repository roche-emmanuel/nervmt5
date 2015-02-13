// Copyright 2015, NervTech
// https://wiki.singularityworld.net

#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"
#property version   "1.00"

#include <nerv/core/Log.mqh>

input int       numInputs = 10;    // Number of input price returns
//input string    symbol='EURUSD';    // Symbol to use for trading.

// Previous prices array:
double prev_prices[10];
// Current prices array:
double cur_prices[10];
// Price return array:
double price_returns[10];

// Initialization function
int OnInit()
{
  Print("Initializing expert with Symbol='", _Symbol, "' and period='", _Period, "'");
  return (INIT_SUCCEEDED);
}

// Deinitialization function
void OnDeinit(const int reason)
{
  Print("Uninitializing expert.");
}

// Tick function
void OnTick()
{
  // Check if we have enough bars:
  if (Bars(_Symbol, _Period) < (numInputs + 1)) // We need at least numInputs+1 bars
  {
    Alert("We don't have enough Bars yet.");
    return;
  }

  // Check if we have a new bar:
  static datetime Old_Time;
  datetime New_Time[1];
  bool IsNewBar = false;

  // copying the last bar time to the element New_Time[0]
  int copied = CopyTime(_Symbol, _Period, 0, 1, New_Time);
  if (copied > 0) // ok, the data has been copied successfully
  {
    if (Old_Time != New_Time[0]) // if old time isn't equal to new bar time
    {
      IsNewBar = true; // if it isn't a first call, the new bar has appeared
      Print("We have new bar here ", New_Time[0], " old time was ", Old_Time);
      Old_Time = New_Time[0];          // saving bar time
    }
  }
  else
  {
    THROW("Error in copying historical times data, error ="+(string)GetLastError());
  }

  //--- EA should only check for new trade if we have a new bar
  if (IsNewBar == false)
  {
    return;
  }

  Print("Got a new bar at time ", Old_Time);

  // Copy the close prices from the bars:
  int count = CopyClose(_Symbol,_Period,0,numInputs,cur_prices);
  CHECK(count==numInputs,"Invalid count for CopyClose");
  
  count = CopyClose(_Symbol,_Period,1,numInputs,prev_prices);
  CHECK(count==numInputs,"Invalid count for CopyClose");

  // Compute the price return array:
  computePriceReturns(price_returns)
  //CHECK(false,"This is a fatal error.");
}

