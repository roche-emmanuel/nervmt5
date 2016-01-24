#include <nerv/core.mqh>
#include <nerv/trading/SignalBase.mqh>

/*
Class: nvVolatilityRange

Base class representing a trader 
*/
class nvVolatilityRange : public nvSignalBase
{
protected:
  // symbol name
  string _symbol;
  ENUM_TIMEFRAMES _period;

  int _handle;

public:
  /*
    Class constructor.
  */
  nvVolatilityRange(string symbol, ENUM_TIMEFRAMES period, int nsessions = 14)
    : _symbol(symbol), _period(period)
  {
    logDEBUG("Creating VolatilityRange "<<symbol)

    _handle = iATR(_symbol,period, nsessions);
    CHECK(_handle>=0,"Invalid ATR handle");

  }

  /*
    Copy constructor
  */
  nvVolatilityRange(const nvVolatilityRange& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvVolatilityRange& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvVolatilityRange()
  {
    logDEBUG("Deleting VolatilityRange")
    IndicatorRelease(_handle);
  }

  double getVolatility()
  {
    double vals[];
    CHECK_RET(CopyBuffer(_handle,0,1,1,vals)==1,0.0,"Cannot copy Volatility buffer");
    return vals[0];
  }

  // Get the current heiken ashi signal:
  virtual double getSignal()
  {
    return 0.0;
  }
};
