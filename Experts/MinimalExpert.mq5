//+------------------------------------------------------------------+
//|                                                MinimalExpert.mq5 |
//|                                         Copyright 2014, NervTech |
//|                                 http://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, NervTech"
#property link      "http://wiki.singularityworld.net"
#property version   "1.00"
//--- input parameters
input int      Input1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
