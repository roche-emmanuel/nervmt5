//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include <nerv/core.mqh>
#include <nerv/math.mqh>

enum PositionType
{
  POSITION_NONE,
  POSITION_LONG,
  POSITION_SHORT
};

class nvStrategy : public nvObject
{
protected:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  datetime _last_bar_time;

public:
  nvStrategy(string symbol, ENUM_TIMEFRAMES period = PERIOD_M1)
  {
    _symbol = symbol;
    _period = period;

    // Save the time of the current bar so that we can start detecting new bars afterwards:
    datetime curTime[1];
    CHECK(CopyTime(_symbol, _period, 0, 1, curTime) == 1, "Cannot retrieve the time of the last bar");
    _last_bar_time = curTime[0];
  }

  ~nvStrategy()
  {
    logDEBUG("Deleting nvStrategy()");
  }

  // Retrieve the expected delta in seconds between two consecutive bars:
  ulong getBarDelta() const
  {
    switch (_period)
    {
    case PERIOD_M1: return 60;
    case PERIOD_M2: return 60 * 2;
    }

    THROW("Invalid period value " << (int)_period);
    return 0;
  }

  void handleTick()
  {
    datetime curTime[1];
    bool IsNewBar = false;

    // copying the last bar time to the element New_Time[0]
    CHECK(CopyTime(_symbol, _period, 0, 1, curTime) == 1, "Cannot retrieve the time of the last bar");

    if (_last_bar_time != curTime[0])
    {
      CHECK(curTime[0] > _last_bar_time, "Going back in time " << curTime[0] << "<" << _last_bar_time);
      ulong diff = curTime[0] - _last_bar_time;
      ulong tdelta = getBarDelta();

      // We have to update the last bar time anyway:
      _last_bar_time = curTime[0];

      CHECK(diff > (tdelta - 1), "Unexpected bar delta difference, diff=" << diff);
      if (diff > tdelta)
      {
        logWARN("More than 1 delta elapsed, missing " << (diff / tdelta - 1.0) << " bar(s).");
        reset();
      }
      else
      {
        // Regular situation:
        MqlRates rates[1];
        CHECK(CopyRates(_symbol, _period, 0, 1, rates) == 1, "Cannot copy new rates");

        // Handle the new bar:
        handleNewBar(rates[0]);
      }
    }
  }

  virtual void reset()
  {
    logDEBUG("Should override to reset the algorithm.");
  }

  virtual void handleNewBar(const MqlRates &rates)
  {
    logDEBUG("Should override to handle new bar. Reading close price: " << rates.close);
  }

  void enterPosition(int pos)
  {
    int cur_pos = getCurrentPosition();
    if (cur_pos != pos)
    {
      // Need to close the previous position if applicable:
      if (cur_pos != POSITION_NONE)
      {
        sendOrder(cur_pos == POSITION_LONG ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
      }

      logDEBUG("Now entering position : " << pos);
      if (pos != POSITION_NONE)
      {
        sendOrder(pos == POSITION_LONG ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      }
    }
  }

  bool sendOrder(ENUM_ORDER_TYPE otype, double price = -1.0, double lot = 1.0)
  {
    MqlTradeRequest tradeRequest;  // To be used for sending our trade requests
    MqlTradeResult tradeResult;    // To be used to get our trade results
    MqlTradeCheckResult checkResult;

    CHECK(otype == ORDER_TYPE_BUY || otype == ORDER_TYPE_SELL, "Unsupported order type: " << (int)otype);

    if (price <= 0.0)
    {
      MqlTick latest_price;

      CHECK(SymbolInfoTick(_symbol, latest_price), "Cannot retrieve the latest price.");
      price = otype == ORDER_TYPE_BUY ? latest_price.ask : latest_price.bid;
    }

    ZeroMemory(tradeRequest);
    tradeRequest.action = TRADE_ACTION_DEAL;                                  // immediate order execution
    tradeRequest.price = NormalizeDouble(price, _Digits);          // latest ask price
    tradeRequest.sl = 0.0; // Stop Loss
    tradeRequest.tp = 0.0; // Take Profit
    tradeRequest.symbol = _symbol;                                            // currency pair
    tradeRequest.volume = lot;                                                 // number of lots to trade
    tradeRequest.magic = 111;                                             // Order Magic Number
    tradeRequest.type = otype;                                        // Buy Order
    tradeRequest.type_filling = ORDER_FILLING_FOK;                             // Order execution type
    tradeRequest.deviation = 10;                                              // Deviation from current price

    // Check the validity of the order:
    ZeroMemory(checkResult);
    bool res = OrderCheck(tradeRequest, checkResult);
    if (!res)
    {
      logERROR("OrderCheck failed.");
      return false;
    }

    //--- send order
    res = OrderSend(tradeRequest, tradeResult);
    if (!res)
    {
      logERROR("OrderSend failed.");
      return false;
    }


    // get the result code
    if (tradeResult.retcode != 10009 && tradeResult.retcode != 10008) //Request is completed or order placed
    {
      logERROR("The order request could not be completed -error:"<<GetLastError());
      ResetLastError();
      return false;
    }

    logDEBUG("Order placed successfully.");
    return true;
  }

  int getCurrentPosition() const
  {
    int pos = POSITION_NONE;

    if (PositionSelect(_symbol) == true) // we have an opened position
    {
      if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
        pos = POSITION_LONG; //It is a Buy
      }
      else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
      {
        pos = POSITION_SHORT; // It is a Sell
      }
      else
      {
        THROW("Invalid position type: " << PositionGetInteger(POSITION_TYPE));
      }
    }

    return pos;
  }
};
