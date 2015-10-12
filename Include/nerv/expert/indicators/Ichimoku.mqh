#include <nerv/core.mqh>
#include <nerv/expert/IndicatorBase.mqh>

/*
Class: nviIchimoku

Our own implementation of the Ichimoku indicator.
*/
class nviIchimoku : public nvIndicatorBase
{
protected:
  // Ichimoku parameters:
  int _tenkanSize;
  int _kijunSize;
  int _senkouSize;

public:
  /*
    Class constructor.
  */
  nviIchimoku(nvCurrencyTrader* trader, ENUM_TIMEFRAMES period=PERIOD_M1)
    : nvIndicatorBase(trader,period)
  {
    CHECK(trader,"Invalid parent trader.");

    _trader = trader;
    _symbol = _trader.getSymbol();
    _period = period;
    
    // Defaoult parameter values:
    _tenkanSize = 9;
    _kijunSize = 26;
    _senkouSize = 52;
  }

  /*
    Copy constructor
  */
  nviIchimoku(const nviIchimoku& rhs) 
    : nvIndicatorBase(rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nviIchimoku& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nviIchimoku()
  {
    // No op.
  }

  /*
  Function: setParameters
  
  Method used to set the indicator parameters
  */
  void setParameters(int tenkan, int kijun, int senkou)
  {
    _tenkanSize = tenkan;
    _kijunSize = kijun;
    _senkouSize = senkou;
  }
  
  /*
  Function: compute
  
  Method used to compute the indicator value at a given time.
  This is the main method that should be overriden by derived classes.
  */
  virtual void compute(datetime time)
  {
    
  }
  

};
