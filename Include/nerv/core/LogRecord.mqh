//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

class nvLogRecord
{
protected:
  nvStringStream _ss;
  int _level;
  string _trace;

public:
  nvLogRecord(int level, string filename, int line, string trace = "")
  {
    _level = level;
    _trace = trace;
    nvLogManager* lm = nvLogManager::instance();

    int flags = lm.getLevelFlags(level);

    if ((flags & nvLogFlags::TIME_STAMP)!=0)
    {
      _ss << lm.getTimeStamp() << " ";
    }

    _ss << "[" << lm.getLevelString(level) << "] ";

    if ((flags & nvLogFlags::FILE_NAME)!=0)
    {
      _ss << "(" << filename <<":"<<line<<") ";
    }

    if (trace != "")
    {
      _ss << "<" << trace << "> ";
    }

    _ss << "  ";
  }

  ~nvLogRecord()
  {
    // Send the record to the log manager:
    nvLogManager::instance().log(_level,_trace,_ss.str());
  }

  nvStringStream *getStream()
  {
    return GetPointer(_ss);
  }
};
