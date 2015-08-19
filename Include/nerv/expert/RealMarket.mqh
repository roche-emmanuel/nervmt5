#include <nerv/core.mqh>
#include <nerv/expert/Market.mqh>

/*
Class: nvRealMarket

Class used to represent the real market, where the currency traders can perform actual (real) trades
with real money... Use carefully :-).
*/
class nvRealMarket : public nvMarket
{
public:
  /*
    Class constructor.
  */
  nvRealMarket()
  {
    _marketType = MARKET_TYPE_REAL;
  }

  /*
    Copy constructor
  */
  nvRealMarket(const nvRealMarket& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvRealMarket& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvRealMarket()
  {
    // No op.
  }

  /*
  Function: sendDealOrder
  
  Method caled to send a concrete deal order on the market.
  */  
  bool sendDealOrder(nvDeal* deal, bool closing = false) //int otype, double lot, double price = 0.0, double sl = 0.0, double tp = 0.0)
  {
    MqlTradeRequest mrequest;

    ENUM_ORDER_TYPE otype = deal.getOrderType();
    if(closing)
    {
      // invert the order type:
      otype = otype==ORDER_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    }

    bool isBuy = otype==ORDER_TYPE_BUY;

    string symbol = deal.getSymbol();
    double bid = SymbolInfoDouble(symbol,SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol,SYMBOL_ASK);

    double price = closing ? deal.getExitPrice() : deal.getEntryPrice();

    double sl = closing ? 0.0 : deal.getStopLossPrice();  
    double lot = deal.getLotSize();
    double tp = 0.0;

    int digits = nvGetNumDigits(symbol);

    ZeroMemory(mrequest);
    mrequest.action = TRADE_ACTION_DEAL;                             // type of action to take
    mrequest.price = NormalizeDouble(price,digits);   // order price
    mrequest.sl = NormalizeDouble(sl,digits);         // Stop Loss
    mrequest.tp = NormalizeDouble(tp,digits);         // take profit
    mrequest.symbol = symbol;                         // currency pair
    mrequest.volume = NormalizeDouble(lot,2);         // number of lots to trade
    mrequest.magic = deal.getCurrencyTrader().getID();// Order Magic Number
    mrequest.type = deal.getOrderType();              // Buy Order
    mrequest.type_filling = ORDER_FILLING_FOK;        // Order execution type
    mrequest.deviation=10;                            // Deviation from current price

    // TODO: Check that the tp is valid in case of buy ?

    //--- send Order
    MqlTradeResult mresult;
    // CHECK(OrderSend(mrequest,mresult),"Invalid result of OrderSend()");
    if(!OrderSend(mrequest,mresult))
    {
      logERROR("Invalid result of OrderSend(): retcode:"<<mresult.retcode);
      return false;
    }

    if(mresult.retcode!=TRADE_RETCODE_DONE)
    {
      logERROR("Invalid send order result retcode: "<<mresult.retcode);
      return false;
    }

    return true;
  }

  /*
  Function: doOpenPosition
  
  Method called to actually open a position on a given symbol on that market.
  Note that the stoploss value is given in number of points.
  */
  virtual bool doOpenPosition(nvDeal* deal, double sl = 0.0)
  {
    // We simply retrieve the last tick on this symbol, the real market 
    // cannot operate on the history !
    MqlTick last_tick;
    CHECK_RET(SymbolInfoTick(deal.getSymbol(),last_tick),false,"Cannot retrieve the latest tick");

    double price = last_tick.bid;

    double point = nvGetPointSize(deal.getSymbol());

    if(deal.getOrderType()==ORDER_TYPE_BUY)
    {
      price = last_tick.ask;      
      deal.setStopLossPrice(price-sl*point);
    }
    else {
      deal.setStopLossPrice(price+sl*point);
    }

    deal.setEntryTime(last_tick.time);
    deal.setEntryPrice(price);

    deal.open();

    // Place the order on the market:
    return sendDealOrder(deal);
  }

  /*
  Function: doClosePosition
  
  Method called to actually close a position on a given symbol on that market.
  Must be reimplemented by derived classes.
  */
  virtual void doClosePosition(nvDeal* deal)
  {
    // We simply retrieve the last tick on this symbol, the real market 
    // cannot operate on the history !
    MqlTick last_tick;
    CHECK(SymbolInfoTick(deal.getSymbol(),last_tick),"Cannot retrieve the latest tick");

    double price = last_tick.ask;

    double point = nvGetPointSize(deal.getSymbol());

    if(deal.getOrderType()==ORDER_TYPE_SELL)
    {
      price = last_tick.bid;      
    }

    deal.setExitTime(last_tick.time);
    deal.setExitPrice(price);

    deal.close();
    
    // Place the order on the market:
    sendDealOrder(deal,true); // closing = true
  }  
};
