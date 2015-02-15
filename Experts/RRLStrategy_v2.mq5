// Copyright 2015, NervTech
// https://wiki.singularityworld.net

#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"
#property version   "1.00"

#include <nerv/trade/RRLStrategy.mqh>

input int       numInputs = 8;    // Number of input price returns
input double 		eta = 0.05;				// Sharpe adaptation factor
input double		rho = 0.11; 			// Learning rate
input double		delta = 0.0005;	// Transaction cost
input double 		maxNorm = 2.0;	// Max theta vector norm (has no real influence on the profits).

nvRRLStrategy* strategy = NULL;

// Initialization function
int OnInit()
{
  Print("Initializing expert with Symbol='", _Symbol, "' and period='", _Period, "'");
  strategy = new nvRRLStrategy(numInputs, rho, eta, delta,maxNorm,_Symbol,_Period);
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

