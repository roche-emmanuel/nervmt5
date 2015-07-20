#include <nerv/core.mqh>
#include <nerv/expert/Security.mqh>

/*
Class: nvTrader

Simple class for the implementation of the basic trader functions
*/
class nvTrader : public nvObject
{
protected:
  nvSecurity _security;
  int _ea_magic; 

public:
  /*
    Class constructor.
  */
  nvTrader(const nvSecurity& sec) : _security(sec)
  {
    _ea_magic = 10001;
  }

  /*
    Copy constructor
  */
  nvTrader(const nvTrader& rhs) : _security(rhs._security)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvTrader()
  {
    // No op.
  }

  /*
  Function: selectPosition
  
  Select the position opened on this security if any.
  Returns:
    true is a position is selected.
  */
  bool selectPosition()
  {
    return PositionSelect(_security.getSymbol());
  }
  
  /*
  Function: hasPosition
  
  Check if this trader is currently in an opened position.
  The position can be either Buy or Sell.
  */
  bool hasPosition()
  {
    return selectPosition();
  }
  
  /*
  Function: getSecurity
  
  Retrieve the nvSecurity object assigned to this trader
  */
  const nvSecurity* getSecurity()
  {
    return GetPointer(_security);
  }
  
  /*
  Function: sendDealOrder
  
  Method used to send a trade order
  */
  bool sendDealOrder(int otype, double lot, double price = 0.0, double sl = 0.0, double tp = 0.0)
  {
    MqlTradeRequest mrequest;

    bool isBuy = otype==ORDER_TYPE_BUY;
    double bid = SymbolInfoDouble(_security.getSymbol(),SYMBOL_BID);
    double ask = SymbolInfoDouble(_security.getSymbol(),SYMBOL_ASK);

    if(price==0.0)
    {
      // use the current price:
      price = isBuy ? ask : bid;

      // Also offset the stop loss and take profit if needed:
      // Note that the stoploss/takeprofit are considered to be relative to the bid price.
      if(sl!=0.0)
      {
        sl = isBuy ? bid - sl : bid + sl;
      }

      if(tp!=0.0)
      {
        tp = isBuy ? bid + tp : bid - tp;
      }
    }

    ZeroMemory(mrequest);
    mrequest.action = TRADE_ACTION_DEAL;                             // type of action to take
    mrequest.price = NormalizeDouble(price,_security.getDigits());   // order price
    mrequest.sl = NormalizeDouble(sl,_security.getDigits());         // Stop Loss
    mrequest.tp = NormalizeDouble(tp,_security.getDigits());         // take profit
    mrequest.symbol = _security.getSymbol();                         // currency pair
    mrequest.volume = NormalizeDouble(lot,2);                                           // number of lots to trade
    mrequest.magic = _ea_magic;                                      // Order Magic Number
    mrequest.type = (ENUM_ORDER_TYPE)otype;                          // Buy Order
    mrequest.type_filling = ORDER_FILLING_FOK;                       // Order execution type
    mrequest.deviation=10;                                           // Deviation from current price

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
  Function: closePosition
  
  Method used to close the current position if any.
  Returns:
    true if a position was closed, false otherwise.
  */
  bool closePosition()
  {
    if(selectPosition())
    {
      // Close the current position:
      bool isBuy = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
      int otype = isBuy ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      double volume = PositionGetDouble(POSITION_VOLUME);

      // Send a deal order:
      sendDealOrder(otype,volume);
    }

    // There was no position to close:
    return false;
  }
  
  /*
  Function: updateSLTP
  
  Method used to update stoploss and/or take profit on a given position
  */
  void updateSLTP(double sl, double tp = 0.0)
  {
    if(!hasPosition())
    {
      // Nothing to update
      return;
    }

    if(sl==0.0)
    {
      sl = PositionGetDouble(POSITION_SL);
    }

    if(tp==0.0)
    {
      tp = PositionGetDouble(POSITION_TP);
    }

    MqlTradeRequest mrequest;
    ZeroMemory(mrequest);
    mrequest.action = TRADE_ACTION_SLTP;                                  // modify stop loss                
    mrequest.sl = NormalizeDouble(sl,_security.getDigits());         // Stop Loss
    mrequest.tp = NormalizeDouble(tp,_security.getDigits());         // take profit
    mrequest.symbol = _security.getSymbol();                         // currency pair
    mrequest.magic = _ea_magic;
    
    // logDEBUG("Previous SL: "<<PositionGetDouble(POSITION_SL)<<", requested new SL: "<<mrequest.sl)

    //--- send Order
    MqlTradeResult mresult;
    // CHECK(OrderSend(mrequest,mresult),"Invalid result of OrderSend()");
    if(!OrderSend(mrequest,mresult))
    {
      logERROR("Invalid result of OrderSend()");
      return;
    }
    
    // selectPosition();
    // logDEBUG("New SL: "<<PositionGetDouble(POSITION_SL))

    CHECK(mresult.retcode==TRADE_RETCODE_DONE,"Invalid send order result retcode: "<<mresult.retcode);    
  }
  
};
