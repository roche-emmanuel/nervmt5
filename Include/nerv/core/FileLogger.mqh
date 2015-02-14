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
  string _filename;

public:
  nvFileLogger(string filename, string name = "") : nvLogSink(name)
  {
  	_filename = filename;
    _handle = INVALID_HANDLE;
  }

  ~nvFileLogger()
  {
    FileClose(_handle);
  }

  virtual void output(int level, const string &trace, const string &msg)
  {
    if(_handle==INVALID_HANDLE) {
      _handle = FileOpen(_filename, FILE_WRITE | FILE_ANSI);
      CHECK(_handle!=INVALID_HANDLE,"Cannot open file "<<_filename);
    }

    FileWriteString(_handle, msg + "\n");
    FileFlush(_handle);
  }

  void close()
  {
    if(_handle!=INVALID_HANDLE) {
      FileClose(_handle);
      _handle = INVALID_HANDLE;
    }
  }
};
