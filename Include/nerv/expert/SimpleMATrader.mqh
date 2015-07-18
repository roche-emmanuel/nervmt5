#include <nerv/core.mqh>
#include <nerv/expert/PeriodTrader.mqh>
#include <nerv/math.mqh>

class SimpleMATrader : public nvPeriodTrader
{
protected:
  int _maHandle;  // handle for our Moving Average indicator
  int _ma4Handle;  // handle for our Moving Average indicator
  double _maVal[]; // Dynamic array to hold the values of Moving Average for each bars
  double _ma4Val[]; // Dynamic array to hold the values of Moving Average of period 4 for each bars
  MqlRates _mrate[];

  double _lot;

public:
  SimpleMATrader(const nvSecurity& sec, ENUM_TIMEFRAMES period) : nvPeriodTrader(sec,period)
  {
    // Prepare the moving average indicator:
    _maHandle=iMA(_security.getSymbol(),_period,20,0,MODE_EMA,PRICE_CLOSE);
    _ma4Handle=iMA(_security.getSymbol(),_period,4,0,MODE_EMA,PRICE_CLOSE);
    
    //--- What if handle returns Invalid Handle    
    CHECK(_maHandle>=0 && _ma4Handle>=0,"Invalid indicators handle");

    // the rates arrays
    ArraySetAsSeries(_mrate,true);
    // the MA-20 values arrays
    ArraySetAsSeries(_maVal,true);
    // the MA-4 values arrays
    ArraySetAsSeries(_ma4Val,true);

    // Lot size:
    _lot = 0.1;
  }

  ~SimpleMATrader()
  {
    logDEBUG("Deleting indicators...")
    
    //--- Release our indicator handles
    IndicatorRelease(_maHandle);
    IndicatorRelease(_ma4Handle);
  }

  void handleBar()
  {
    string symbol = _security.getSymbol();

    // MqlTick latest_price;
    MqlTick latest_price;
    CHECK(SymbolInfoTick(symbol,latest_price),"Cannot retrieve latest price.")

    // Get the details of the latest 4 bars
    CHECK(CopyRates(symbol,_period,0,4,_mrate)==4,"Cannot copy the latest rates");
    CHECK(CopyBuffer(_maHandle,0,0,4,_maVal)==4,"Cannot copy MA buffer 0");
    CHECK(CopyBuffer(_ma4Handle,0,0,4,_ma4Val)==4,"Cannot copy MA buffer 0");

    double prev_ema = _maVal[0];
    double prev_ema4 = _ma4Val[0];

    if(selectPosition())
    {

      bool isBuy = PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
      
      // Check if the MA4 is still going in the proper direction:
      // if((isBuy && _ma4Val[0]<_ma4Val[1]) || (!isBuy && _ma4Val[0]>_ma4Val[1]))
      // {
      //   closePosition();
      //   return;
      // }      

      double nsl = prev_ema;
      double stoploss = PositionGetDouble(POSITION_SL);
      double takeprofit = PositionGetDouble(POSITION_TP);

      nsl = isBuy ? MathMax(nsl,stoploss) : MathMin(nsl,stoploss);

      // Also update the take profit at 2x the diff between the ma4 and ma20
      // double tp = isBuy ? prev_ema4 + 1.5*(prev_ema4-prev_ema) : prev_ema4 - 1.5*(prev_ema - prev_ema4);
      
      // if(nsl!=stoploss || tp!=takeprofit) {
      //   updateSLTP(nsl,tp);
      // }

      if(nsl!=stoploss) {
        updateSLTP(nsl);
      }

      return;
    }

    double delta3 = _ma4Val[3]-_maVal[3];
    double delta2 = _ma4Val[2]-_maVal[2];
    double delta1 = _ma4Val[1]-_maVal[1];
    double delta0 = _ma4Val[0]-_maVal[0];

    if( delta2>2.0*MathAbs(delta3)
      && delta1>1.1*delta2
      && delta0>1.1*delta1)
    {
      // place a buy order:
      double price = latest_price.ask;
      double sl = prev_ema;
      double tp = 0.0;

      logDEBUG("Placing buy order")
      sendDealOrder(ORDER_TYPE_BUY,_lot,price,sl,tp);
    }

    if( delta2<-2.0*MathAbs(delta3)
      && delta1<1.1*delta2
      && delta0<1.1*delta1)
    {
      // place a buy order:
      double price = latest_price.bid;
      double sl = prev_ema;
      double tp = 0.0;

      logDEBUG("Placing sell order")
      sendDealOrder(ORDER_TYPE_SELL,_lot,price,sl,tp);
    }

  }
};
