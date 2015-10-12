#include <nerv/core.mqh>
#include <nerv/expert/CurrencyTrader.mqh>

struct nvIndicatorBuffer {
  double data[];
};

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

  // History size:
  // specify the size of the history we want to keep:
  uint _historySize;

  //  List of buffers used to store the indicator history data:
  nvIndicatorBuffer _buffers[];

  // last bar time for this indicator:
  datetime _prevBarTime;

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
    _historySize = 1;
    _prevBarTime = 0;
    ArrayResize( _buffers, 0 );
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
  Function: setHistorySize
  
  Specify the size that should be used for the history of this indicator:
  */
  void setHistorySize(uint size)
  {
    CHECK(ArraySize( _buffers )==0,"Changing history size after buffers allocation is not permitted.");
    _historySize = size;
  }
  
  /*
  Function: setBuffer
  
  Method called to set a value in a given buffer index,
  it that index is out of range, then the corresponding buffer is allocated.
  Note that we always set the front slot of the buffers: the other values 
  are only readable.
  */
  void setBuffer(uint index, double value)
  {
    allocateUntilBuffer(index);

    _buffers[index].data[0] = value;
  }
  
  /*
  Function: getBuffer
  
  Retrieve a value from a buffer given a buffer index and
  an optional position in the buffer data
  */
  double getBuffer(uint index, uint pos = 0)
  {
    allocateUntilBuffer(index);

    CHECK_RET(pos < (uint)ArraySize(_buffers[index].data),0.0,"Invalid buffer position");
    return _buffers[index].data[pos];
  }
  
  /*
  Function: allocateBuffer
  
  Method used to allocate a buffer an all the buffers before it
  */
  int allocateBuffer()
  {
    int index = ArraySize(_buffers);

    ArrayResize(_buffers,index+1);
    ArrayResize( _buffers[index].data, 1 );
    _buffers[index].data[0] = 0.0;
    return index;    
  }
  
  /*
  Function: allocateBuffer
  
  Allocate a buffer with a given index
  */
  void allocateUntilBuffer(uint index)
  {
    while((uint)ArraySize( _buffers ) <= index) {
      allocateBuffer();
    }
  }
  
  /*
  Function: saveBuffers
  
  Save the current value in the buffers:
  */
  void saveBuffers()
  {
    if(_historySize<=1)
      return; // nothing to backup here.

    // Start a new value for all the buffers:
    int num = ArraySize( _buffers );
    double val;
    for(int i =0;i<num;++i) {
      val = _buffers[i].data[0];
      nvPrependArrayElement(_buffers[i].data,val,_historySize);
    }
  }
  
  /*
  Function: compute
  
  Method used to compute the indicator value at a given time.
  This is the main method that should be overriden by derived classes.
  */
  virtual void compute(datetime time)
  {
    // Check if we need to write a new bar value:
    datetime New_Time[1];

    // copying the last bar time to the element New_Time[0]
    int copied=CopyTime(_symbol,_period,time,1,New_Time);
    CHECK(copied==1,"Invalid result for CopyTime operation: "<<copied);

    if(_prevBarTime!=New_Time[0]) // if old time isn't equal to new bar time
    {
      _prevBarTime=New_Time[0];            // saving bar time  
      saveBuffers();
    }

    doCompute(time);
  }
    
  /*
  Function: doCompute
  
  Actual method that should be overriden by the concrete indicator implementations
  to perform the needed computations
  */
  virtual void doCompute(datetime time)
  {
    // No op.
  }
  

};
