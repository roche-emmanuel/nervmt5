/*
This is the version 1 of the Nerv EA.
This implementation is mainly based on the tsunami strategy
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

#include <nerv/core.mqh>

// Initialization method:
int OnInit()
{
  logDEBUG("Initializing Nerv EA.")
  return 0;
}

// Uninitialization:
void OnDeinit(const int reason)
{
  logDEBUG("Uninitializing Nerv EA.")
}


// OnTick handler:
void OnTick()
{
  logDEBUG("In OnTick handler.")
}
