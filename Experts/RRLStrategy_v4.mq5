// Copyright 2015, NervTech
// https://wiki.singularityworld.net

#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"
#property version   "1.00"

#include <nerv/trade/RRLStrategyDry.mqh>

input int       numInputs = 10;    // Number of input price returns
input int       trainLen = 600;    // Training duration
input int       evalLen = 100;    // Evaluation duration
input double    transCost = 0.0001; // Transaction cost
input int       maxCGIters = 30; // Max number of CG iterations.

nvRRLStrategy* strategy = NULL;

// Initialization function
int OnInit()
{
  Print("Initializing expert with Symbol='", _Symbol, "' and period='", _Period, "'");
  strategy = new nvRRLStrategyDry(transCost, numInputs, trainLen, evalLen, _Symbol,_Period);
  strategy.setMaxIterations(maxCGIters);
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

