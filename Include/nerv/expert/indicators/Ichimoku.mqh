#include <nerv/core.mqh>
#include <nerv/expert/IndicatorBase.mqh>
#include <nerv/core/CyclicBuffer.mqh>

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

  nvCyclicBuffer _tenkanHigh;
  nvCyclicBuffer _tenkanLow;

  // Last update time:
  datetime _lastUpdateTime;

public:
  /*
    Class constructor.
  */
  nviIchimoku(nvCurrencyTrader* trader, ENUM_TIMEFRAMES period=PERIOD_M1)
    : nvIndicatorBase(trader,period)
  { 
    ArraySetAsSeries(_rates,true);

    // Default parameter values:
    setParameters(9,26,52);
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
    _maxNumBar = MathMax(_tenkanSize,MathMax(_kijunSize,_senkouSize))+_kijunSize;
    reset();
  }
  
  /*
  Function: reset
  
  method called to reset the previously computed data in this indicator 
  */
  void reset()
  {
    _lastUpdateTime = 0;
    _tenkanHigh.resize(_tenkanSize);
    _tenkanLow.resize(_tenkanSize);
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
    // check how we compare to the last update time:
    // if(time < _lastUpdateTime) {
    //   reset();
    // }

    // MqlRates src[];

    // if(_lastUpdateTime==0) {
    //   // we need to cache all the data:
    //   // So we retrieve the current bar time:
    //   _lastUpdateTime = nvGetBarTime(_symbol,_period,time);

    //   // Retrieve all the rates that we might need to init the buffers:
    //   CHECK(CopyRates(_symbol,_period,time,_maxNumBar,src)==_maxNumBar,"Cannot copy rates.");

    //   int offset = _maxNumBar-_tenkanSize;
    //   for(int i=0;i<_tenkanSize;++i) {
    //     _tenkanHigh.push_back(src[i+offset].high);
    //     _tenkanLow.push_back(src[i+offset].low);
    //   }

    //   // for(int i=0;i<_kijunSize;++i) {
    //   //   _kijunHigh.push_back(_rates[i].high);
    //   //   _kijunLow.push_back(_rates[i].low);
    //   // }

    // }

    // // Check how many bar have elapsed since the last update:
    // int num = (int)MathFloor( (time - _lastUpdateTime)/(double)_periodDuration );

    // _lastUpdateTime  += num*_periodDuration;

    // // retrieve this number of bars to inject them
    // // (plus one for the current one)
    // CHECK(CopyRates(_symbol,_period,time,num+1,src)==num+1,"Cannot copy rates.");
    // for(int i=0;i<num;++i) {
    //   _tenkanHigh.push_back(src[i].high);
    //   _tenkanLow.push_back(src[i].low);
    // }

    // _tenkanHigh.set_back(src[num].high);
    // _tenkanLow.set_back(src[num].low);


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

    high = Highest(_rates,_senkouSize,offset);
    low = Lowest(_rates,_senkouSize,offset);
    setBuffer(ICHI_SPAN_B,(high+low)*0.5);
  }
  

};
