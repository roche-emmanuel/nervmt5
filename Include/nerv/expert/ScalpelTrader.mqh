#include <nerv/core.mqh>
#include <nerv/expert/PeriodTrader.mqh>
#include <nerv/math.mqh>

/*
This trader will implement the strategy described on the page:
http://www.youtrading.com/fr/introduction-au-forex/728-scalping
*/

enum ENUM_PT_TREND
{
  TREND_NONE,
  TREND_LONG,
  TREND_SHORT
};

class ScalpelTrader : public nvPeriodTrader
{
protected:
  int _ma377Handle;  // handle for our Moving Average indicator
  int _ma55Handle;  // handle for our Moving Average indicator
  int _bolHandle;  // Handle to bollinger indicator
  int _rsiHandle;  // Handle to RSI indicator
  int _stochHandle; // Handle to stochastic indicator
  
  double _ma377Val[]; // Dynamic array to hold the values of Moving Average for each bars
  double _ma55Val[]; // Dynamic array to hold the values of Moving Average of period 4 for each bars
  double _bolMaxVal[]; // Bollinger max band
  double _bolMinVal[]; // Bollinger min band
  double _bolMeanVal[]; // Bollinger mean band
  double _rsiVal[]; // RSI values
  double _stochVal[]; //Stochastic values

  MqlRates _mrate[];

  double _lot;

public:
  ScalpelTrader(const nvSecurity& sec, ENUM_TIMEFRAMES period) : nvPeriodTrader(sec,period)
  {
    // Prepare the moving average indicator:
    _ma377Handle=iMA(_symbol,_period,377,0,MODE_SMMA,PRICE_CLOSE);
    CHECK(_ma377Handle>=0,"Invalid handle");
    _ma55Handle=iMA(_symbol,_period,55,0,MODE_SMMA,PRICE_CLOSE);
    CHECK(_ma55Handle>=0,"Invalid handle");
    _bolHandle=iBands(_symbol,_period,20,0,2.5,PRICE_CLOSE);
    CHECK(_bolHandle>=0,"Invalid handle");
    _rsiHandle=iRSI(_symbol,_period,14,PRICE_CLOSE);
    CHECK(_rsiHandle>=0,"Invalid handle");
    _stochHandle=iStochastic(_symbol,_period,5,3,3,MODE_SMMA,STO_LOWHIGH);
    CHECK(_stochHandle>=0,"Invalid handle");

    ArraySetAsSeries(_mrate,true);
    ArraySetAsSeries(_ma377Val,true);
    ArraySetAsSeries(_ma55Val,true);
    ArraySetAsSeries(_bolMaxVal,true);
    ArraySetAsSeries(_bolMinVal,true);
    ArraySetAsSeries(_bolMeanVal,true);
    ArraySetAsSeries(_rsiVal,true);
    ArraySetAsSeries(_stochVal,true);

    // Lot size:
    _lot = 0.1;
  }

  ~ScalpelTrader()
  {
    logDEBUG("Deleting indicators...")

    IndicatorRelease(_ma377Handle);
    IndicatorRelease(_ma55Handle);
    IndicatorRelease(_bolHandle);
    IndicatorRelease(_rsiHandle);
    IndicatorRelease(_stochHandle);
  }


  void handleBar()
  {

  }

  void handleTick()
  {
    // Retrieve latest quote:
    MqlTick latest_price;
    CHECK(SymbolInfoTick(_symbol,latest_price),"Cannot retrieve latest price.")
    double bid = latest_price.bid;
    double ask = latest_price.bid;
    double point = _security.getPoint();

    if(selectPosition())
    {
      // Update the trailing stop:
      // double sl = PositionGetDouble(POSITION_SL);
      // bool isBuy = PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;

      // // Update the stoploss to get closer to the bid price progressively:
      // double closesl = bid + (isBuy ? -1.0:1.0)*10*point;
      // double coeff = 0.05;
      // double nsl = sl * (1.0 - coeff) + closesl * coeff;

      // nsl = isBuy ? MathMax(nsl,sl) : MathMin(nsl,sl);
      // if(nsl!=sl)
      // {
      //   // logDEBUG("Updated new stoploss: "<<nsl)
      //   updateSLTP(nsl);
      // }

      return;
    }


    // Retrieve indicator values:
    CHECK(CopyBuffer(_ma377Handle,0,0,1,_ma377Val)==1,"Cannot copy MA377 buffer 0");
    CHECK(CopyBuffer(_ma55Handle,0,0,1,_ma55Val)==1,"Cannot copy MA55 buffer 0");
    CHECK(CopyBuffer(_bolHandle,0,0,1,_bolMaxVal)==1,"Cannot copy Bollinger band buffer 0");
    CHECK(CopyBuffer(_bolHandle,1,0,1,_bolMinVal)==1,"Cannot copy Bollinger band buffer 1");
    CHECK(CopyBuffer(_bolHandle,2,0,1,_bolMeanVal)==1,"Cannot copy Bollinger band buffer 2");
    CHECK(CopyBuffer(_rsiHandle,0,0,1,_rsiVal)==1,"Cannot copy RSI buffer 0");
    CHECK(CopyBuffer(_stochHandle,0,0,1,_stochVal)==1,"Cannot copy Stochastic buffer 0");


    // Check if we meet the sell conditions:
    if(_ma55Val[0] < _ma377Val[0] && bid > _bolMaxVal[0] && _rsiVal[0] > 65.0 && _stochVal[0] > 80.0)
    {
      // Place a sell order with tp of 3 to 5 and sl of 12 pips:
      sendDealOrder(ORDER_TYPE_SELL,_lot,bid,bid+120*point,bid-30*point);
      // sendDealOrder(ORDER_TYPE_SELL,_lot,bid,bid+120*point,0.0); //bid-30*point);
    }

    // Check if we meet the buy conditions:
    if(_ma55Val[0] > _ma377Val[0] && bid < _bolMinVal[0] && _rsiVal[0] < 30.0 && _stochVal[0] < 20.0)
    {
      // Place a buy order with tp of 3 to 5 and sl of 12 pips:
      sendDealOrder(ORDER_TYPE_BUY,_lot,ask,bid-120*point,bid+30*point);
      // sendDealOrder(ORDER_TYPE_BUY,_lot,ask,bid-120*point,0.0); //bid+30*point);
    }
  }
};
