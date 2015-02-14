//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include "LogSink.mqh"

class nvFileLogger : public nvLogSink
{
protected:
  int _handle;

public:
  nvFileLogger(string filename, string name = "") : nvLogSink(name)
  {
    _handle = FileOpen(filename, FILE_WRITE | FILE_ANSI);
  }

  ~nvFileLogger()
  {
    FileClose(_handle);
  }

  virtual void output(int level, const string &trace, const string &msg)
  {
    FileWriteString(_handle, msg + "\n");
    FileFlush(_handle);
  }
};
