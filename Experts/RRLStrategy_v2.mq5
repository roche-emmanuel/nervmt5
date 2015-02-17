// Copyright 2015, NervTech
// https://wiki.singularityworld.net

#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"
#property version   "1.00"

#include <nerv/trade/RRLStrategy.mqh>

input int       numInputs = 12;    // Number of input price returns
input double 		eta = 0.01;				// Sharpe adaptation factor
input double		rho = 0.01; 			// Learning rate
input double		tcost = 0.00008;	// Transaction cost
input double 		maxNorm = 2.0;	// Max theta vector norm (has no real influence on the profits).
input ulong			warmUpDuration = 0; // WarmUp duration

nvRRLStrategy* strategy = NULL;

// Initialization function
int OnInit()
{
  Print("Initializing expert with Symbol='", _Symbol, "' and period='", _Period, "'");
  strategy = new nvRRLStrategy(numInputs, rho, eta, tcost,maxNorm,_Symbol,_Period);
  strategy.setWarmUp(warmUpDuration);
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

