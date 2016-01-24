#include <nerv/core.mqh>
#include <nerv/trading/SignalBase.mqh>

/*
Class: nvHASignal

Base class representing a trader 
*/
class nvHASignal : public nvSignalBase
{
protected:
  // symbol name
  string _symbol;
  ENUM_TIMEFRAMES _period;

  datetime _lastTime;
  int _dur;

  // cached signal value:
  double _signal;

  int _handle;
  int _mean;

public:
  /*
    Class constructor.
  */
  nvHASignal(string symbol, ENUM_TIMEFRAMES period)
    : _symbol(symbol), _period(period)
  {
    logDEBUG("Creating HASignal "<<symbol)

    _lastTime = 0;
    _dur = nvGetPeriodDuration(period);
    _signal = 0.0;
    _mean = 1;

    _handle = iCustom(_symbol,period,"nerv\\HeikenAshi");
    CHECK(_handle>=0,"Invalid Heiken Ashi direction handle");

  }

  /*
    Copy constructor
  */
  nvHASignal(const nvHASignal& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvHASignal& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvHASignal()
  {
    logDEBUG("Deleting HASignal")
    IndicatorRelease(_handle);
  }

  // Get the current heiken ashi signal:
  virtual double getSignal()
  {
    datetime ctime = TimeCurrent();
    if((ctime - _lastTime)<_dur) {
      return _signal;
    }
    _lastTime = ctime;

    CHECK_RET(_mean>=1,0.0,"Invalid mean value: "<<_mean)

    double vals[];
    CHECK_RET(CopyBuffer(_handle,4,1,_mean,vals)==_mean,0.0,"Cannot copy HA buffer");

    double sig = nvGetMeanEstimate(vals);
    sig = (sig-0.5)*2.0;

    if((sig < 0.0 && vals[0]==1.0) || (sig>0.0 && vals[0]==0.0))
      sig = 0.0;

    _signal = sig;  
    return _signal;
  }
};
