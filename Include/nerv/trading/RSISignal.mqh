#include <nerv/core.mqh>
#include <nerv/trading/SignalBase.mqh>

/*
Class: nvRSISignal

Base class representing a trader 
*/
class nvRSISignal : public nvSignalBase
{
protected:
  // symbol name
  string _symbol;
  ENUM_TIMEFRAMES _period;

  int _handle;
  double _rmin;
  double _rmax;

public:
  /*
    Class constructor.
  */
  nvRSISignal(string symbol, ENUM_TIMEFRAMES period, int nsessions = 14, double rmin=30.0, double rmax=70)
    : _symbol(symbol), _period(period)
  {
    logDEBUG("Creating RSISignal "<<symbol)

    _handle = iRSI(_symbol,period, nsessions,PRICE_CLOSE);
    CHECK(_handle>=0,"Invalid ATR handle");
    _rmin = rmin;
    _rmax = rmax;
  }

  /*
    Copy constructor
  */
  nvRSISignal(const nvRSISignal& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvRSISignal& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvRSISignal()
  {
    logDEBUG("Deleting RSISignal")
    IndicatorRelease(_handle);
  }

  // Get the current signal:
  virtual double getSignal()
  {
    double vals[];
    CHECK_RET(CopyBuffer(_handle,0,1,1,vals)==1,0.0,"Cannot copy RSI buffer");
    
    if(vals[0]<_rmin)
      return 1.0;
    if(vals[0]>_rmax)
      return -1.0;

    return 0.0;
  }
};
