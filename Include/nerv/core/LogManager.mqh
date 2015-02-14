//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include "ConsoleLogger.mqh"

enum nvLogFlags
{
  FILE_NAME = 1,
  TIME_STAMP = 2
};

/** Severity level values. Those values defines the available default levels.*/
enum nvLogSeverity
{
  LOGSEV_FATAL,
  LOGSEV_ERROR,
  LOGSEV_WARNING,
  LOGSEV_NOTICE,
  LOGSEV_INFO,
  LOGSEV_DEBUG0,
  LOGSEV_DEBUG1,
  LOGSEV_DEBUG2,
  LOGSEV_DEBUG3,
  LOGSEV_DEBUG4,
  LOGSEV_DEBUG5,
  NUM_SEV_LEVELS
};


class nvLogManager
{
//public:
  //class LogHandler : public nvObject {
  //public:
  //  virtual void handle(int level, const string& trace, const string& msg) {};
  //};

protected:
  bool _verbose;
  int _notifyLevel;
  CList _sinks;
  int _levelFlags[];

protected:
  // Protected constructor and destructor:
  nvLogManager(void)
  {
    _verbose = false;
    _notifyLevel = LOGSEV_DEBUG5;
    ArrayResize(_levelFlags,NUM_SEV_LEVELS);
    ArrayFill(_levelFlags,0,NUM_SEV_LEVELS,0);
    Print("Creating LogManager.");
  };

  ~nvLogManager(void)
  {
    Print("Destroying LogManager.");
  };

public:
  // Retrieve the instance of this log manager:
  static nvLogManager *instance()
  {
    static nvLogManager singleton;
    return GetPointer(singleton);
  }

  bool getVerbose() const
  {
    return _verbose;
  }

  void setVerbose(bool verbose)
  {
    _verbose = verbose;
  }

  string getTimeStamp() const
  {
    return (string)TimeLocal();
  }

  void log(int level, const string &trace, string msg)
  {
    if(_sinks.Total()==0)
      _sinks.Add(new nvConsoleLogger("default_console_sink")); // add a console logger by default.

    // iterate on all the available sinks:
    nvLogSink* sink = (nvLogSink*)_sinks.GetFirstNode();
    while(sink) {
      sink.process(level,trace,msg);
      sink = (nvLogSink*)_sinks.GetNextNode();
    }
  }

  void addSink(nvLogSink* sink)
  {
    CHECK(sink!=NULL,"Invalid logSink argument.");
    _sinks.Add(sink);
  }

  int getNotifyLevel() const
  {
    return _notifyLevel;
  }

  void setNotifyLevel(int level)
  {
    _notifyLevel = level;
  }

  int getLevelFlags(int level) const
  {
    return _levelFlags[level];
  }

  void setLevelFlags(int level, int flags)
  {
    _levelFlags[level] = flags;
  }

  string getLevelString(int level) const
  {
    switch(level) {
    case LOGSEV_FATAL: return "FATAL"; 
    case LOGSEV_ERROR: return "ERROR"; 
    case LOGSEV_WARNING: return "WARNING"; 
    case LOGSEV_NOTICE: return "NOTICE"; 
    case LOGSEV_INFO: return "INFO"; 
    case LOGSEV_DEBUG0: return "DEBUG"; 
    case LOGSEV_DEBUG1: return "DEBUG1"; 
    case LOGSEV_DEBUG2: return "DEBUG2"; 
    case LOGSEV_DEBUG3: return "DEBUG3"; 
    case LOGSEV_DEBUG4: return "DEBUG4"; 
    case LOGSEV_DEBUG5: return "DEBUG5"; 
    default:
      return "DEBUGX";
    }
  }
};