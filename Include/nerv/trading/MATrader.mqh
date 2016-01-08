#include <nerv/core.mqh>

#include <nerv/trading/SecurityTrader.mqh>

/*
Class: nvMATrader

Base class representing a trader 
*/
class nvMATrader : public nvSecurityTrader
{
protected:
  // Handles for Day MA slow and fast
  int _maDSHandle;  // handle for our Moving Average indicator
  int _maDFHandle;  // handle for our Moving Average indicator
  
  // Handles for Hour MA slow and fast
  int _maHSHandle;  // handle for our Moving Average indicator
  int _maHFHandle;  // handle for our Moving Average indicator
  

  double _maSVal[]; // Dynamic array to hold the values of Moving Average for each bars
  double _maFVal[]; // Dynamic array to hold the values of Moving Average of period 4 for each bars
  MqlRates _mrate[];

public:
  /*
    Class constructor.
  */
  nvMATrader(string symbol)
    :nvSecurityTrader(symbol)
  {
    _maDSHandle=iMA(symbol,PERIOD_H1,34,0,MODE_EMA,PRICE_CLOSE);
    _maDFHandle=iMA(symbol,PERIOD_H1,8,0,MODE_EMA,PRICE_CLOSE);
    
    _maHSHandle=iMA(symbol,PERIOD_M5,34,0,MODE_EMA,PRICE_CLOSE);
    _maHFHandle=iMA(symbol,PERIOD_M5,8,0,MODE_EMA,PRICE_CLOSE);
    
    //--- What if handle returns Invalid Handle    
    CHECK(_maDSHandle>=0 && _maDFHandle>=0,"Invalid indicators handle");
    CHECK(_maHSHandle>=0 && _maHFHandle>=0,"Invalid indicators handle");

    // the rates arrays
    ArraySetAsSeries(_mrate,true);
    // the MA-20 values arrays
    ArraySetAsSeries(_maSVal,true);
    // the MA-4 values arrays
    ArraySetAsSeries(_maFVal,true);
  }

  /*
    Copy constructor
  */
  nvMATrader(const nvMATrader& rhs) : nvSecurityTrader("")
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvMATrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvMATrader()
  {
    logDEBUG("Deleting SecurityTrader")
  }
  
  virtual double getSignal(datetime ctime)
  {
    // check if we are in a buy or sell precondition:
    // using the day MAs:

    CHECK_RET(CopyRates(_symbol,PERIOD_H1,0,4,_mrate)==4,0.0,"Cannot copy the latest rates");
    CHECK_RET(CopyBuffer(_maDSHandle,0,0,4,_maSVal)==4,0.0,"Cannot copy MA buffer 0");
    CHECK_RET(CopyBuffer(_maDFHandle,0,0,4,_maFVal)==4,0.0,"Cannot copy MA buffer 0");

    double sSlope1 = _maSVal[1]-_maSVal[2];
    double sSlope2 = _maSVal[2]-_maSVal[3];
    double fSlope1 = _maFVal[1]-_maFVal[2];
    double fSlope2 = _maFVal[2]-_maFVal[3];

    // Check the curves positions:
    bool b1 = _maFVal[1]>_maSVal[1] && _maFVal[2]>_maSVal[2] && _maFVal[3]>_maSVal[3];

    // Chech the slopes are positives:
    bool b2 = sSlope1 > sSlope2 && sSlope2 > 0.0;
    bool b3 = fSlope1 > fSlope2 && fSlope2 > 0.0;

    // Check the current price position:
    bool b4 = _mrate[0].close > _maFVal[0];

    // Check the price evolution:
    bool b5 = _mrate[0].close > _mrate[1].close;

    bool buycond = b1 && b2 && b2 && b4 && b5;

    if(buycond)
    {
      // We are in a good buy position, so now we check the hour trend:
      CHECK_RET(CopyRates(_symbol,PERIOD_M5,0,4,_mrate)==4,0.0,"Cannot copy the latest rates");
      CHECK_RET(CopyBuffer(_maHSHandle,0,0,4,_maSVal)==4,0.0,"Cannot copy MA buffer 0");
      CHECK_RET(CopyBuffer(_maHFHandle,0,0,4,_maFVal)==4,0.0,"Cannot copy MA buffer 0");

      sSlope1 = _maSVal[1]-_maSVal[2];
      sSlope2 = _maSVal[2]-_maSVal[3];
      fSlope1 = _maFVal[1]-_maFVal[2];
      fSlope2 = _maFVal[2]-_maFVal[3];

      // Buy if we meet the previous conditions on this lower time frame:
      bool bb1 = _maFVal[1]>_maSVal[1] && _maFVal[2]>_maSVal[2] && _maFVal[3]>_maSVal[3];

      // Chech the slopes are positives:
      bool bb2 = sSlope1 > sSlope2 && sSlope2 > 0.0;
      bool bb3 = fSlope1 > fSlope2 && fSlope2 > 0.0;

      // Check the current price position:
      bool bb4 = _mrate[0].close > _maFVal[0];

      // Check the price evolution:
      bool bb5 = _mrate[0].close > _mrate[1].close;

      if(bb1 && bb2 && bb2 && bb4 && bb5) 
      {
         return 1.0;
      }
    }

    return 0.0;
  }

  virtual void checkPosition()
  {
    if(!hasPosition(_security))
      return; // nothing to do.

    // We close the current position if the fast MA is going under the slow MA:
    // on the hour time scale:
    CHECK(CopyRates(_symbol,PERIOD_M5,0,4,_mrate)==4,"Cannot copy the latest rates");
    CHECK(CopyBuffer(_maHSHandle,0,0,4,_maSVal)==4,"Cannot copy MA buffer 0");
    CHECK(CopyBuffer(_maHFHandle,0,0,4,_maFVal)==4,"Cannot copy MA buffer 0");

    bool c1 = _maFVal[0]< _maSVal[0];
    bool c2 = _mrate[1].close<_maFVal[1];

    if (_isBuy && (c1 || c2))
    {
      closePosition(_security);
    }
  }

  virtual double getTrailingOffset(MqlTick& last_tick)
  {
    return (last_tick.ask - last_tick.bid);
  }

};
