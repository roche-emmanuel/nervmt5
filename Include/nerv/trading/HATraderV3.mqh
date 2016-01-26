#include <nerv/core.mqh>
#include <nerv/trading/SecurityTrader.mqh>
#include <nerv/trading/HASignal.mqh>
#include <nerv/trading/VolatilityRange.mqh>
#include <nerv/trading/RSISignal.mqh>

/*
Class: nvHATraderV3

This version 3 of the HA Trader will introduce a signal 

*/
class nvHATraderV3 : public nvSecurityTrader {
protected:
  nvHASignal* _HA0;
  nvHASignal* _HA1;
  nvHASignal* _HA2;
  nvHASignal* _HA3;
  nvHASignal* _HA4;

  nvVolatilityRange* _vrange;
  nvRSISignal*_rsi;

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
  nvHATraderV3(string symbol, ENUM_TIMEFRAMES period = PERIOD_H4)
    : nvSecurityTrader(symbol)
  {
    logDEBUG("Creating HATrader")
    _HA0 = new nvHASignal(symbol,PERIOD_W1);
    _HA1 = new nvHASignal(symbol,PERIOD_D1);
    _HA2 = new nvHASignal(symbol,PERIOD_H4);
    _HA3 = new nvHASignal(symbol,PERIOD_M30);
    _HA4 = new nvHASignal(symbol,PERIOD_M5);
    
    _rsi = new nvRSISignal(symbol,PERIOD_M30);

    _vrange = new nvVolatilityRange(symbol,PERIOD_M30);

    _lastDir = 0.0;
    _lastTime = 0;
    _stopLoss = 0.0;
    _dur = 0; //5*60;

    double psize = nvGetPointSize(_symbol);
    _trailOffset = 2000.0*psize;
    _trail = 1000.0*psize;

    setRiskLevel(0.1);
  }

  /*
    Class destructor.
  */
  ~nvHATraderV3()
  {
    logDEBUG("Deleting HATrader")
    RELEASE_PTR(_HA0);
    RELEASE_PTR(_HA1);
    RELEASE_PTR(_HA2);
    RELEASE_PTR(_HA3);
    RELEASE_PTR(_HA4);
    RELEASE_PTR(_vrange);
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

    // Close the current position if needed:
    if(hasPosition())
    {
      // if(_lastDir*sig3 < 0.0)
      // {
      //   close();
      // }
      
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
      return;
    }

    double sig0 = _HA0.getSignal();
    double sig1 = _HA1.getSignal();
    double sig2 = _HA2.getSignal();
    double sig3 = _HA3.getSignal();
    double sig4 = _HA4.getSignal();
    double rsi = _rsi.getSignal();

    datetime ctime = TimeCurrent();
    if((ctime-_lastTime)<_dur)
    {
      return;
    }

    _lastTime = ctime;

    double newDir = 0.0;
    if(sig0>0.0 && sig1>0.0 && sig2>0.0 && sig3>0.0 && sig4>0.0)
    {
      newDir = 1.0;
    }
    if(sig0<0.0 && sig1<0.0 && sig2<0.0 && sig3<0.0 && sig4<0.0)
    {
      newDir = -1.0;
    }

    if(!hasPosition() && newDir!=0.0)
    {
      // Get the current range:
      double range = _vrange.getVolatility();

      double sl = range*4.0;
      
      _trailOffset = range/2.0;
      _trail = range/4.0;

      // Evaluate an appropriate lot size given the sl value:
      double lot = evaluateLotSize(sl/_psize,1.0);
      if(lot<0.01)
      {
        logDEBUG("Discarding too small lot.");
        return;
      }

      int otype = newDir > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double bid = nvGetBid(_symbol);
      openPosition(otype,lot);

      _lastDir = newDir;
      _entryPrice = otype==ORDER_TYPE_BUY ? nvGetAsk(_symbol) : nvGetBid(_symbol);
    }
  }
};
