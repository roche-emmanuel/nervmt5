//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

class nvLogSink : public nvObject
{
protected:
  string _name;
  bool _enabled;

public:
  nvLogSink(string name = "")
  {
    _name = name;
    _enabled = true;
  }

  void setEnabled(bool enable)
  {
    _enabled = enable;
  }

  string getName() const
  {
    return _name;
  }

  void process(int level, const string &trace, const string &msg)
  {
    if (!_enabled)
      return;

    output(level,trace,msg);
  }

  virtual void output(int level, const string &trace, const string &msg)
  {
    // Do nothing by default.
  }
};