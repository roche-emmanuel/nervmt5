/*
This is the version 2 of the Nerv EA.
This implementation will use the MACD indicators with the PeriodTrader handler.
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

#include <nerv/core.mqh>
#include <nerv/expert/PeriodTrader.mqh>

input int      StopLoss=30;      // Stop Loss
input int      TakeProfit=100;   // Take Profit
input int      ADX_Period=8;     // ADX Period
input int      MA_Period=8;      // Moving Average Period
input double   Adx_Min=22.0;     // Minimum ADX Value
input double   Lot=0.1;          // Lots to Trade

nvPeriodTrader* trader;

class MACDTrader : public nvPeriodTrader
{
protected:
  int _adxHandle; // handle for our ADX indicator
  int _maHandle;  // handle for our Moving Average indicator
  double _plsDI[], _minDI[], _adxVal[]; // Dynamic arrays to hold the values of +DI, -DI and ADX values for each bars
  double _maVal[]; // Dynamic array to hold the values of Moving Average for each bars
  MqlRates _mrate[];
  double _p_close; // Variable to store the close value of a bar
  int _STP;
  int _TKP;

public:
  MACDTrader(const nvSecurity& sec) : nvPeriodTrader(sec,PERIOD_H1)
  {
    //--- Get handle for ADX indicator
    _adxHandle=iADX(_security.getSymbol(),_period,ADX_Period);
    
    //--- Get the handle for Moving Average indicator
    _maHandle=iMA(_security.getSymbol(),_period,MA_Period,0,MODE_EMA,PRICE_CLOSE);
    
    //--- What if handle returns Invalid Handle    
    CHECK(_adxHandle>=0 && _maHandle>=0,"Invalid indicators handle");

    _STP = StopLoss*10;
    _TKP = TakeProfit*10;

    // the rates arrays
    ArraySetAsSeries(_mrate,true);
    // the ADX DI+values array
    ArraySetAsSeries(_plsDI,true);
    // the ADX DI-values array
    ArraySetAsSeries(_minDI,true);
    // the ADX values arrays
    ArraySetAsSeries(_adxVal,true);
    // the MA-8 values arrays
    ArraySetAsSeries(_maVal,true);
  }

  ~MACDTrader()
  {
    logDEBUG("Deleting indicators...")
    
    //--- Release our indicator handles
    IndicatorRelease(_adxHandle);
    IndicatorRelease(_maHandle);
  }

  void handleBar()
  {
    string symbol = _security.getSymbol();

    MqlTick latest_price;
    CHECK(SymbolInfoTick(symbol,latest_price),"Cannot retrieve latest price.")

    // Get the details of the latest 3 bars
    CHECK(CopyRates(symbol,_period,0,3,_mrate)==3,"Cannot copy the latest rates");
    CHECK(CopyBuffer(_adxHandle,0,0,3,_adxVal)==3,"Cannot copy ADX buffer 0");
    CHECK(CopyBuffer(_adxHandle,1,0,3,_plsDI)==3,"Cannot copy ADX buffer 1");
    CHECK(CopyBuffer(_adxHandle,2,0,3,_minDI)==3,"Cannot copy ADX buffer 2");
    CHECK(CopyBuffer(_maHandle,0,0,3,_maVal)==3,"Cannot copy MA buffer 0");

    // Do we have positions opened already?
    bool Buy_opened=false;  // variable to hold the result of Buy opened position
    bool Sell_opened=false; // variables to hold the result of Sell opened position

    // if(selectPosition())
    // {
    //   if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
    //   {
    //     Buy_opened=true;  //It is a Buy
    //   }
    //   else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
    //   {
    //     Sell_opened=true; // It is a Sell
    //   }
    // }

    double point = _security.getPoint();


    if(selectPosition())
    {
      double price = PositionGetDouble(POSITION_PRICE_OPEN);

      // Check if we are currently making profit:
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
      {
        // This is a buy position,
        if(latest_price.bid > (price + _STP*point*1.0)) {
          double nsl = (latest_price.bid + price)*0.5;
          
          // logDEBUG("Might update stop loss with new value: "<< nsl)
          double stoploss = PositionGetDouble(POSITION_SL);

          if(nsl>(stoploss+20*point)) {

            logDEBUG("Updating stoploss to: "<<nsl<<" with open price: "<<price)

            updateSLTP(nsl);
          }

          return; // Should no do anything else in that case.
        }

        Buy_opened=true;  //It is a Buy
      }
      else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
      {
        if(latest_price.ask < (price - _STP*point*1.0)) {
          double nsl = (latest_price.ask + price)*0.5;
          
          // logDEBUG("Might update stop loss with new value: "<< nsl)
          double stoploss = PositionGetDouble(POSITION_SL);

          if(nsl<(stoploss-20*point)) {

            logDEBUG("Updating stoploss to: "<<nsl<<" with open price: "<<price)

            updateSLTP(nsl);
          }

          return; // Should no do anything else in that case.
        }

        Sell_opened=true; // It is a Sell
      }
    }

    // Copy the bar close price for the previous bar prior to the current bar, that is Bar 1
    _p_close=_mrate[1].close;  // bar 1 close price


    /*
      1. Check for a long/Buy Setup : MA-8 increasing upwards, 
      previous price close above it, ADX > 22, +DI > -DI
    */

    //--- Declare bool type variables to hold our Buy Conditions
    bool Buy_Condition_1=(_maVal[0]>_maVal[1]) && (_maVal[1]>_maVal[2]); // MA-8 Increasing upwards
    bool Buy_Condition_2 = (_p_close > _maVal[1]);         // previuos price closed above MA-8
    bool Buy_Condition_3 = (_adxVal[0]>Adx_Min);          // Current ADX value greater than minimum value (22)
    bool Buy_Condition_4 = (_plsDI[0]>_minDI[0]);          // +DI greater than -DI

    if(Buy_Condition_1 && Buy_Condition_2 && Buy_Condition_3 && Buy_Condition_4)
    {
      if(Buy_opened) {
        logDEBUG("We already have a buy position opened.")
        return;
      }

      double price = latest_price.ask;
      double sl = latest_price.ask - _STP*point;
      double tp = latest_price.ask + _TKP*point;

      // otherwise open a buy position:
      sendDealOrder(ORDER_TYPE_BUY,Lot,price,sl,tp);
    }

    /*
      2. Check for a Short/Sell Setup : MA-8 decreasing downwards, 
      previous price close below it, ADX > 22, -DI > +DI
    */
    
    //--- Declare bool type variables to hold our Sell Conditions
    bool Sell_Condition_1 = (_maVal[0]<_maVal[1]) && (_maVal[1]<_maVal[2]);  // MA-8 decreasing downwards
    bool Sell_Condition_2 = (_p_close <_maVal[1]);                         // Previous price closed below MA-8
    bool Sell_Condition_3 = (_adxVal[0]>Adx_Min);                         // Current ADX value greater than minimum (22)
    bool Sell_Condition_4 = (_plsDI[0]<_minDI[0]);                         // -DI greater than +DI

    if(Sell_Condition_1 && Sell_Condition_2 && Sell_Condition_3 && Sell_Condition_4)
    {
      if(Sell_opened) {
        logDEBUG("We already have a sell position opened.")
        return;
      }

      double price = latest_price.bid;
      double sl = latest_price.bid + _STP*point;
      double tp = latest_price.bid - _TKP*point;

      // otherwise open a sell position:
      sendDealOrder(ORDER_TYPE_SELL,Lot,price,sl,tp);
    }
  }
};

// Initialization method:
int OnInit()
{
  // Enable logging to file:
  nvLogManager* lm = nvLogManager::instance();
  string fname = "nerv_ea_v1.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  logDEBUG("Initializing Nerv EA.")
  nvSecurity sec("EURUSD",5,0.00001);
  trader = new MACDTrader(sec);

  return 0;
}

// Uninitialization:
void OnDeinit(const int reason)
{
  logDEBUG("Uninitializing Nerv EA.")
  RELEASE_PTR(trader)
}


// OnTick handler:
void OnTick()
{
  trader.onTick();
}
