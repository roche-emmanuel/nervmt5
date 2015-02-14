//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include "LogSink.mqh"

class nvConsoleLogger : public nvLogSink
{

public:
  nvConsoleLogger(string name = "") : nvLogSink(name) {}

  virtual void output(int level, const string &trace, const string &msg)
  {
    // Print to console:
    Print(msg);
  }
};