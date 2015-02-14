//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

// Base class for all NervTech elements.
class nvObject
{
public:
  nvObject() {};
  ~nvObject() {};

  virtual string toString() const
  {
    return "[nvObject]";
  }
};