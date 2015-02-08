//+------------------------------------------------------------------+
//|                                                   TickReader.mq5 |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  //---
  Print("I'm in OnInit() callback.");

  //---
  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  //---

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  Print("I'm in OnTick() callback.");

  MqlTick last_tick;
  if (SymbolInfoTick(Symbol(), last_tick))
  {
    Print(last_tick.time, ": Bid = ", last_tick.bid,
          " Ask = ", last_tick.ask, "  Volume = ", last_tick.volume);
  }
  else Print("SymbolInfoTick() failed, error = ", GetLastError());

}
//+------------------------------------------------------------------+
