#include <nerv/core.mqh>

#include <nerv/rnn/TraderBase.mqh>
#include <nerv/rnn/PredictionSignalFile.mqh>
#include <nerv/rnn/RemoteSignal.mqh>

/*
Class: nvForcastSecurityTrader

Base class representing a trader 
*/
class nvForcastSecurityTrader : public nvSecurityTrader
{
protected:
  double _signals[];
  int _holdingPeriodCount;

  int _ma;
  double _maVal[];

public:
  /*
    Class constructor.
  */
  nvForcastSecurityTrader(string symbol, double entry)
    : nvSecurityTrader(symbol,entry)
  {
    logDEBUG("Creating Forcast Security Trader for "<<symbol)
    ArrayResize( _signals, 0 );

    _ma = iMA(_symbol,PERIOD_M1,4,0,MODE_LWMA,PRICE_TYPICAL);

    // the rates arrays
    ArraySetAsSeries(_maVal,true);
  }

  /*
    Copy constructor
  */
  nvForcastSecurityTrader(const nvForcastSecurityTrader& rhs) : nvSecurityTrader("",0.0)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvForcastSecurityTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvForcastSecurityTrader()
  {
    IndicatorRelease(_ma);
  }
  
  /*
  Function: getClosestValidSignal
  
  Retrieve the closest valid signal if any
  */
  double getClosestValidSignal()
  {
    int len = ArraySize( _signals );
    // for(int i=0;i<len;++i)
    // {
    //   if(MathAbs(_signals[i])>_entryThreshold)
    //     return _signals[i];
    // }
    // return 0.0;

    double sig = 0.0;
    for(int i=0;i<len;++i)
    {
      if(MathAbs(_signals[i])>_entryThreshold && MathAbs(_signals[i]) > MathAbs(sig))
      {
        sig = _signals[i];
      }
    }

    return sig;
  }
  
  virtual double getTrailDelta(MqlTick& last_tick)
  {
    // return (last_tick.ask - last_tick.bid);
    return -1;
  }

  /*
  Function: update
  
  Method called to update the state of this trader 
  normally once per minute
  */
  virtual void update(datetime ctime)
  {
    if(_lastUpdateTime>=ctime)
      return; // Nothing to process.

    _lastUpdateTime = ctime;
    // logDEBUG("Update cycle at: " << ctime << " = " << (int)ctime)

    // Retrieve the prediction signal at that time:
    double pred = getPrediction(ctime-60);

    // First we need to push this on our forcast buffer:
    nvAppendArrayElement(_signals,pred,10);

    double sig = getClosestValidSignal();

    // If the slope of the MA is agains the signal, then we do not
    // enter the desired position
    CHECK(CopyBuffer(_ma,0,0,4,_maVal)==4,"Cannot copy MA buffer 0");

    double s1 = _maVal[1]-_maVal[2];
    double s2 = _maVal[2]-_maVal[3];

    // If we are already in a position we just wait for completion.
    if(hasPosition(_security)) {
      // if the position is already profitable then we just keep trailing.
      if(_profitable)
        return;

      //  We check if the current closest valid prediction matches
      // our current position, and if not we close it right away:  
      if((_isBuy && sig < 0.0) || (!_isBuy && sig > 0.0))
      {
        // Preemptively closing position:
        closePosition(_security);
      }
      else if(_holdingPeriodCount > 20) {
        // Do not hold loosing position for too long:
        closePosition(_security);
      }
      else if(s1*sig<=0.0 && s2*sig <= 0.0)
      {
        closePosition(_security);
      }
      else {
        // Just let the position run further...
        _holdingPeriodCount++;
        return;
      }
    }
    else {
      // Reset the period count:
      _holdingPeriodCount = 0;
  
      if(MathAbs(sig)<=_entryThreshold)
        return; // Should not enter anything.

      //  We could consider that sig basically tell us
      // what tendency we should trade on.
      // Check the current moving average to see if we should enter
      // a trade:

      if(sig*s1<=0.0) {
        return; // prevent the trade.
      }

      // Let's check if we should open a position:
      openPosition(sig);
    }
  }
};
