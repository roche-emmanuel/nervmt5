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

public:
  /*
    Class constructor.
  */
  nvForcastSecurityTrader(string symbol, double entry)
    : nvSecurityTrader(symbol,entry)
  {
    logDEBUG("Creating Forcast Security Trader for "<<symbol)
    ArrayResize( _signals, 0 );
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
  }
  
  /*
  Function: getClosestValidSignal
  
  Retrieve the closest valid signal if any
  */
  double getClosestValidSignal()
  {
    int len = ArraySize( _signals );
    for(int i=0;i<len;++i)
    {
      if(_signals[i]>_entryThreshold)
        return _signals[i];
    }

    return 0.0;
  }
  
  virtual double getTrailDelta(MqlTick& last_tick)
  {
    return (last_tick.ask - last_tick.bid);
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
    double pred = getPrediction(ctime);

    // First we need to push this on our forcast buffer:
    nvAppendArrayElement(_signals,pred,10);

    double sig = getClosestValidSignal();

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
      else {
        // Just let the position run further...
        _holdingPeriodCount++;
        return;
      }
    }
    
    // Reset the period count:
    _holdingPeriodCount = 0;

    // Let's check if we should open a position:
    if(sig!=0.0 && !hasPosition(_security)) {
      openPosition(sig);
    }
  }
};
