/*
This is the version 1 of the Nerv EA.
This implementation is mainly based on the tsunami strategy
*/

#property copyright "Copyright 2015, Nervtech"
#property link      "http://www.nervtech.org"

#property version   "1.00"

#include <nerv/core.mqh>
#include <nerv/expert/Trader.mqh>

int EA_Magic = 12345;   // EA Magic Number
double STP = 20;
double TKP = 40;
double Lot = 0.1;

nvTrader* trader;

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
  trader = new nvTrader(sec);

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
  //logDEBUG("In OnTick handler.")

  // Check if we have an open position:
  bool opened = trader.hasPosition();

  double point = trader.getSecurity().getPoint();
  string symbol = trader.getSecurity().getSymbol();
  
  // We retrieve the latest tick info:
  MqlTick latest_price;
  CHECK(SymbolInfoTick(symbol,latest_price),"Cannot get the latest price quote - error:"<<GetLastError());

  double spread = (latest_price.ask - latest_price.bid)/point;
  logDEBUG("Current price: "<<latest_price.ask<<", spread: "<<spread<<", time: "<<latest_price.time)

  if(!opened) {
    // There is currently no position opened for this currency,
    // so we can open one:
    if(spread>STP) {
      return; // Do not place an order in that case.
    }


    double price = latest_price.ask;
    double sl = latest_price.ask - STP*point;
    double tp = latest_price.ask + TKP*point;

    logDEBUG("Opening trade at price: "<<price)
    trader.sendDealOrder(ORDER_TYPE_BUY,Lot,price,sl,tp);
  }
  else {
    // We already have a position opened.
    // Currently this can only be BUY position.
    // We need to check if we should update the stop loss because we are currently getting money:
    // double price = HistoryDealGetDouble(deal,DEAL_PRICE);
    // double price = PositionGetDouble(POSITION_PRICE_OPEN);
    logDEBUG("Checking existing deal setup at price: "<<price)

    // If the current bid price is higher than the deal buy price, then we are making money:
    if(latest_price.bid > (price + STP*point*0.5)) {

      double nsl = (latest_price.bid + price)*0.5;
      
      // logDEBUG("Might update stop loss with new value: "<< nsl)
      double stoploss = PositionGetDouble(POSITION_SL);

      if(nsl>(stoploss+10*point)) {

        logDEBUG("Updating stoploss to: "<<nsl<<" with open price: "<<price)

        trader.updateSLTP(nsl);
      }
    }
  }
}
