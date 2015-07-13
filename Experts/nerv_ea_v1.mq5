/*
This is the version 1 of the Nerv EA.
This implementation is mainly based on the tsunami strategy
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

#include <nerv/core.mqh>

string symbol;
int digits;
double point;

ulong deal = 0;

int EA_Magic = 12345;   // EA Magic Number
double STP = 20;
double TKP = 300;
double lot = 0.1;
double stoploss;
double takeprofit;
double dealprice;

// Initialization method:
int OnInit()
{
  // Enable logging to file:
  // nvLogManager* lm = nvLogManager::instance();
  // string fname = "nerv_ea_v1.log";
  // nvFileLogger* logger = new nvFileLogger(fname);
  // lm.addSink(logger);

  logDEBUG("Initializing Nerv EA.")

  // Here we should specify the symbols that we should like to trade:
  symbol = "EURUSD";
  digits = 5; // 5 digits for EURUSD
  point = 0.00001;


  logDEBUG("Symbol: "<<_Symbol<<", Digits: "<<_Digits<<", Point: "<<_Point)

  return 0;
}

// Uninitialization:
void OnDeinit(const int reason)
{
  logDEBUG("Uninitializing Nerv EA.")
}


// OnTick handler:
void OnTick()
{
  //logDEBUG("In OnTick handler.")

  // Check if we have an open position:
  bool opened = PositionSelect(symbol);

  // We retrieve the latest tick info:
  MqlTick latest_price;
  CHECK(SymbolInfoTick(symbol,latest_price),"Cannot get the latest price quote - error:"<<GetLastError());

  double spread = (latest_price.ask - latest_price.bid)/point;
  logDEBUG("Current price: "<<latest_price.ask<<", spread: "<<spread)

  if(!opened) {
    // There is currently no position opened for this currency,
    // so we can open one:

    // For now let's say we always place a buy order:
    MqlTradeRequest mrequest;
    MqlTradeResult mresult;

    if(spread>STP) {
      return; // Do not place an order in that case.
    }

    ZeroMemory(mrequest);
    mrequest.action = TRADE_ACTION_DEAL;                               // immediate order execution
    dealprice = NormalizeDouble(latest_price.ask,digits);           // latest ask price
    mrequest.price = dealprice;
    stoploss = NormalizeDouble(latest_price.ask - STP*point,digits);    // Stop Loss
    mrequest.sl = stoploss; 
    takeprofit = NormalizeDouble(latest_price.ask + TKP*point,digits);  // Take Profit
    mrequest.tp = takeprofit; 
    mrequest.symbol = symbol;                                            // currency pair
    mrequest.volume = lot;                                                 // number of lots to trade
    mrequest.magic = EA_Magic;                                             // Order Magic Number
    mrequest.type = ORDER_TYPE_BUY;                                        // Buy Order
    mrequest.type_filling = ORDER_FILLING_FOK;                             // Order execution type
    mrequest.deviation=100;                                                // Deviation from current price

    logDEBUG("Placing deal with price: "<<dealprice)
    //--- send Order
    CHECK(OrderSend(mrequest,mresult),"Invalid result of OrderSend()");

    CHECK(mresult.retcode==TRADE_RETCODE_DONE,"Invalid send order result retcode: "<<mresult.retcode);
    deal = mresult.deal;
    CHECK(deal>0,"Invalid deal number");
  }
  else {
    // We already have a position opened.
    // Currently this can only be BUY position.
    // We need to check if we should update the stop loss because we are currently getting money:
    // double price = HistoryDealGetDouble(deal,DEAL_PRICE);
    double price = dealprice;
    logDEBUG("Checking existing deal setup at price: "<<price)

    // If the current bid price is higher than the deal buy price, then we are making money:
    if(latest_price.bid > (price + STP*point*0.5)) {

      double nsl = NormalizeDouble((latest_price.bid + price)*0.5,digits);
      logDEBUG("Might update stop loss with new value: "<< nsl)

      if(nsl>stoploss) {
        // We need to update the stop loss here:
        stoploss = nsl;

        MqlTradeRequest mrequest;
        MqlTradeResult mresult;

        ZeroMemory(mrequest);
        mrequest.action = TRADE_ACTION_SLTP;                                  // modify stop loss                
        mrequest.sl = stoploss; 
        mrequest.tp = takeprofit; 
        mrequest.symbol = symbol;                                            // currency pair

        //--- send Order
        CHECK(OrderSend(mrequest,mresult),"Invalid result of OrderSend for SLTP()");

        CHECK(mresult.retcode==TRADE_RETCODE_DONE,"Invalid send order result retcode for SLTP:"<<mresult.retcode);
      }
    }
  }
}
