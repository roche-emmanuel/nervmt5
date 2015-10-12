#include <nerv/core.mqh>
#include <nerv/expert/CurrencyTrader.mqh>

/*
Class: nvIndicatorBase

Class used as a base class for all indicators what we can build.
*/
class nvIndicatorBase : public nvObject
{
protected:
  nvCurrencyTrader* _trader;

  // The period used inside this agent:
  ENUM_TIMEFRAMES _period;

  // Symbol name:
  string _symbol;

public:
  /*
    Class constructor.
  */
  nvIndicatorBase(nvCurrencyTrader* trader, ENUM_TIMEFRAMES period=PERIOD_M1)
  {
    CHECK(trader,"Invalid parent trader.");

    _trader = trader;
    _symbol = _trader.getSymbol();
    _period = period;
  }

  /*
    Copy constructor
  */
  nvIndicatorBase(const nvIndicatorBase& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvIndicatorBase& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvIndicatorBase()
  {
    // No op.
  }

  /*
  Function: getPeriod
  
  Retrieve the period used by this trader.
  */
  ENUM_TIMEFRAMES getPeriod()
  {
    return _period;
  }

  /*
  Function: compute
  
  Method used to compute the indicator value at a given time.
  This is the main method that should be overriden by derived classes.
  */
  void compute(datetime time)
  {
    // No op.
  }
  

};
