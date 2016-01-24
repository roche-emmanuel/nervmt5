#include <nerv/core.mqh>
#include <nerv/utils.mqh>

#include <nerv/trading/SecurityTrader.mqh>

/*
Class: nvMultiTrader

Base class representing a trader 
*/
class nvMultiTrader : public nvObject
{
protected:
  nvSecurityTrader* _traders[];

  datetime _lastUpdate;
  int _updateDelay;

public:
  /*
    Class constructor.
  */
  nvMultiTrader(ENUM_TIMEFRAMES period)
  {
    logDEBUG("Creating new Multi Trader with time frame " << EnumToString(period))
    _lastUpdate = 0;
    _updateDelay = nvGetPeriodDuration(period);
  }

  /*
    Class destructor.
  */
  ~nvMultiTrader()
  {
    logDEBUG("Deleting MultiTrader")
    int len = ArraySize(_traders);
    for(int i=0;i<len;++i)
    {
      RELEASE_PTR(_traders[i]);  
    }
    ArrayResize( _traders, 0 );
  }

  /*
  Function: addTrader
  
  Method to add a security trader
  */
  nvSecurityTrader* addTrader(nvSecurityTrader* trader)
  {
    nvAppendArrayElement(_traders,trader);
    return trader;
  }
  
  /*
  Function: update
  
  Method called to update the state of this trader 
  normally once per minute
  */
  void update()
  {
    // Only perform an update if the update delay is passed:
    datetime ctime = TimeCurrent();
    if((ctime-_lastUpdate)<_updateDelay)
    {
      return;
    }

    // perform the update:
    _lastUpdate = ctime;

    int len = ArraySize( _traders );
    for(int i = 0;i<len;++i)
    {
      _traders[i].update(ctime);  
    }
  }

  void onTick()
  {
    // Should handle onTick  here.
    int len = ArraySize( _traders );
    for(int i = 0;i<len;++i)
    {
      _traders[i].onTick();  
    }
  }
};
