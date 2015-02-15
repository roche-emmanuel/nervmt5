// Copyright 2015, NervTech
// https://wiki.singularityworld.net

#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"
#property version   "1.00"

#include <nerv/trade/RRLStrategy.mqh>

input int       numInputs = 10;    // Number of input price returns

nvRRLStrategy* strategy = NULL;

// Initialization function
int OnInit()
{
  Print("Initializing expert with Symbol='", _Symbol, "' and period='", _Period, "'");
  strategy = new nvRRLStrategy(numInputs,_Symbol,_Period);
  return (INIT_SUCCEEDED);
}

// Deinitialization function
void OnDeinit(const int reason)
{
  Print("Uninitializing expert.");
  delete strategy;
}

// Tick function
void OnTick()
{
  strategy.handleTick();
}

