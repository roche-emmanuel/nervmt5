#include <nerv/core.mqh>
#include <nerv/trading/SecurityTrader.mqh>
#include <nerv/trading/HASignal.mqh>

/*
Class: nvHATraderV2

Base class representing a trader 
*/
class nvHATraderV2 : public nvSecurityTrader {
protected:
  nvHASignal* _HA1;
  nvHASignal* _HA2;

  double _lastDir;
  int _dur;
  datetime _lastTime;

  double _stopLoss;
  double _trail;
  double _trailOffset;
  double _entryPrice;

public:
  /*
    Class constructor.
  */
  nvHATraderV2(string symbol, ENUM_TIMEFRAMES period = PERIOD_H4)
    : nvSecurityTrader(symbol)
  {
    logDEBUG("Creating HATrader")
    _HA1 = new nvHASignal(symbol,PERIOD_D1);
    _HA2 = new nvHASignal(symbol,PERIOD_H4);

    _lastDir = 0.0;
    _lastTime = 0;
    _stopLoss = 0.0;
    _dur = 3600.0;

    double psize = nvGetPointSize(_symbol);
    _trailOffset = 2500.0*psize;
    _trail = 1000.0*psize;
  }

  /*
    Class destructor.
  */
  ~nvHATraderV2()
  {
    logDEBUG("Deleting HATrader")
    RELEASE_PTR(_HA1);
    RELEASE_PTR(_HA2);
  }

  virtual void update(datetime ctime)
  {

  }
  
  void close()
  {
    if(hasPosition())
    {
      closePosition();
      _lastDir = 0.0;
      _stopLoss = 0.0;
    }
  }

  void checkStopLoss()
  {
    if(!hasPosition() || _stopLoss==0.0)
      return;

    double bid = nvGetBid(_symbol);
    if(isLong())
    {
      if(bid<=_stopLoss)
      {
        close();
      }
      else
      {
        _stopLoss = MathMax(_stopLoss,bid-_trail);
      }
    }
    else
    {
      if(bid>=_stopLoss)
      {
        close();
      }
      else
      {
        _stopLoss = MathMin(_stopLoss, bid+_trail);
      }

    }
  }
  virtual void onTick()
  {
    double sig1 = _HA1.getSignal();
    double sig2 = _HA2.getSignal();

    // Close th current position if needed:
    if(hasPosition())
    {
      if(_lastDir*sig2 < 0.0)
      {
        close();
      }
      
      double bid = nvGetBid(_symbol);
      
      if(_stopLoss == 0.0)
      {
        if(isLong() && bid > (_entryPrice + _trailOffset))
        {
          _stopLoss = bid - _trail;
          logDEBUG("Added stoploss at "<<_stopLoss<<" for LONG position.")
        }

        if(isShort() && bid < (_entryPrice - _trailOffset))
        {
          _stopLoss = bid + _trail;
          logDEBUG("Added stoploss at "<<_stopLoss<<" for SHORT position.")
        }
      }

      checkStopLoss();
    }

    datetime ctime = TimeCurrent();
    if((ctime-_lastTime)<_dur)
    {
      return;
    }

    _lastTime = ctime;

    double newDir = 0.0;
    if(sig1>0.0 && sig2>0.0)
    {
      newDir = 1.0;
    }
    if(sig1<0.0 && sig2<0.0)
    {
      newDir = -1.0;
    }

    if(!hasPosition() && newDir!=0.0)
    {
      // if we are not in a position, we open a new one randomly:
      int otype = newDir > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      openPosition(otype,0.1);      
      _lastDir = newDir;
      _entryPrice = otype==ORDER_TYPE_BUY ? nvGetAsk(_symbol) : nvGetBid(_symbol);
    }
  }
};
