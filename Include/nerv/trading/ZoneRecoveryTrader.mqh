#include <nerv/core.mqh>

#include <nerv/trading/SecurityTrader.mqh>

/*
Class: nvZoneRecoveryTrader

Base class representing a trader 
*/
class nvZoneRecoveryTrader : public nvSecurityTrader
{
protected:
  // Handles for Day MA slow and fast
  // int _maDSHandle;  // handle for our Moving Average indicator
  // int _maDFHandle;  // handle for our Moving Average indicator
  
  // // Handles for Hour MA slow and fast
  // int _maHSHandle;  // handle for our Moving Average indicator
  // int _maHFHandle;  // handle for our Moving Average indicator
  

  // double _maSVal[]; // Dynamic array to hold the values of Moving Average for each bars
  // double _maFVal[]; // Dynamic array to hold the values of Moving Average of period 4 for each bars
  // MqlRates _mrate[];

  ENUM_TIMEFRAMES _period;

public:
  /*
    Class constructor.
  */
  nvZoneRecoveryTrader(string symbol,ENUM_TIMEFRAMES period)
    :nvSecurityTrader(symbol), _period(period)
  {
    // _maDSHandle=iMA(symbol,PERIOD_H1,34,0,MODE_EMA,PRICE_CLOSE);
    // _maDFHandle=iMA(symbol,PERIOD_H1,8,0,MODE_EMA,PRICE_CLOSE);
    
    // _maHSHandle=iMA(symbol,PERIOD_M5,34,0,MODE_EMA,PRICE_CLOSE);
    // _maHFHandle=iMA(symbol,PERIOD_M5,8,0,MODE_EMA,PRICE_CLOSE);
    
    // //--- What if handle returns Invalid Handle    
    // CHECK(_maDSHandle>=0 && _maDFHandle>=0,"Invalid indicators handle");
    // CHECK(_maHSHandle>=0 && _maHFHandle>=0,"Invalid indicators handle");

    // // the rates arrays
    // ArraySetAsSeries(_mrate,true);
    // // the MA-20 values arrays
    // ArraySetAsSeries(_maSVal,true);
    // // the MA-4 values arrays
    // ArraySetAsSeries(_maFVal,true);
  }

  /*
    Copy constructor
  */
  nvZoneRecoveryTrader(const nvZoneRecoveryTrader& rhs) : nvSecurityTrader(""), _period(PERIOD_M1)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvZoneRecoveryTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvZoneRecoveryTrader()
  {
    logDEBUG("Deleting ZoneRecoveryTrader")
  }
  
  virtual void update(datetime ctime)
  {
    MqlTick latest_price;
    CHECK(SymbolInfoTick(_symbol,latest_price),"Cannot retrieve latest price.")
    double bid = latest_price.bid;
        
    if(hasPosition())
    {
      // We are already in a position.
      bool isBuy = isLong();

      if(isBuy && bid > (_zoneHigh + _targetProfit))
      {
        // Update the stoploss of the position:
        double nsl = bid - MathMin((bid-_zoneHigh)/2.0,_trail);
        if( nsl > getStopLoss())
        {
          updateSLTP(nsl);
        } 
      }

      if(!isBuy && bid < (_zoneLow - _targetProfit))
      {
        // Update the stoploss of the position:
        double nsl = bid + MathMin((_zoneLow-bid)/2.0,_trail);
        if( nsl < getStopLoss())
        {
          updateSLTP(nsl);
        }
      }

      if(!isBuy && bid > _zoneHigh) 
      {
        toggleHedge(ORDER_TYPE_BUY,latest_price.ask);
      }

      if(isBuy && bid < _zoneLow) 
      {
        toggleHedge(ORDER_TYPE_SELL,latest_price.bid);
      }
    }
    else {
      // We are not yet in a position
      double price = latest_price.bid;
      double spread = latest_price.ask - latest_price.bid;
      
    }

  }

  virtual void onTick()
  {

  }

};
