#include <nerv/core.mqh>
#include <nerv/expert/IndicatorBase.mqh>

// Buffer indices used in this indicator:
#define ICHI_TENKAN 0
#define ICHI_KIJUN  1
#define ICHI_SPAN_A 2
#define ICHI_SPAN_B 3
#define ICHI_CHINKOU 4

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
  int _maxNumBar;
  
  MqlRates _rates[];

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
    
    ArraySetAsSeries(_rates,true);

    // Defaoult parameter values:
    _tenkanSize = 9;
    _kijunSize = 26;
    _senkouSize = 52;
    _maxNumBar = 52;
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
    _maxNumBar = MathMax(_tenkanSize,MathMax(_kijunSize,_senkouSize));
  }
  
  double Highest(const MqlRates& array[], int range, int offset = 0)
  {
    double res=0;
    res=array[offset].high;
    for(int i=0;i<range;i++)
    {
      if(res<array[offset+i].high) res=array[offset+i].high;
    }

    return res;
  }

  double Lowest(const MqlRates& array[], int range, int offset = 0)
  {
    double res=0;
   
    res=array[offset].low;
    for(int i=0;i<range;i++)
    {
      if(res>array[offset+i].low) res=array[offset+i].low;
    }

    return res;
  }

  /*
  Function: compute
  
  Method used to compute the indicator value at a given time.
  This is the main method that should be overriden by derived classes.
  */
  virtual void doCompute(datetime time)
  {
    // Retrieve all the rates that we need to perform the computation:
    CHECK(CopyRates(_symbol,_period,time,_maxNumBar,_rates)==_maxNumBar,"Cannot copy rates.");

    double high, low, tenkanVal, kijunVal;
    int offset;

    setBuffer(ICHI_CHINKOU,_rates[0].close);
    
    high = Highest(_rates,_tenkanSize);
    low = Lowest(_rates,_tenkanSize);
    setBuffer(ICHI_TENKAN,(high+low)*0.5);

    high = Highest(_rates,_kijunSize);
    low = Lowest(_rates,_kijunSize);
    setBuffer(ICHI_KIJUN,(high+low)*0.5);

    // There should be a plot shift of kijunSize applied for the span A
    offset = _kijunSize;
    high = Highest(_rates,_tenkanSize,offset);
    low = Lowest(_rates,_tenkanSize,offset);
    tenkanVal = (high+low)*0.5;

    high = Highest(_rates,_kijunSize,offset);
    low = Lowest(_rates,_kijunSize,offset);
    kijunVal = (high+low)*0.5;

    setBuffer(ICHI_SPAN_A,(tenkanVal+kijunVal)*0.5);

    high = Highest(_rates,_senkouSize);
    low = Lowest(_rates,_senkouSize);
    setBuffer(ICHI_SPAN_B,(high+low)*0.5);
  }
  

};
