//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

class nvLogManager
{
protected:
	// Protected constructor and destructor:
  nvLogManager(void) {};
  ~nvLogManager(void) {};

public:
  // Retrieve the instance of this log manager:
  nvLogManager &instance()
  {
    static nvLogManager singleton;
    return singleton;
  }

};