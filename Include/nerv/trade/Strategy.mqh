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
  ulong _frameCount;
  ulong _warmUpCount;

  // Confidence vector:
  nvVecd *_confs;

  // Confidence adaptation:
  double _confAdaptation;

  // best price observed for the current position:
  double _best_price;

  // Stop lost mean value in pips:
  double _stopMean;
  // Stop lost deviation value in pips:
  double _stopDev;

public:
  nvStrategy(string symbol, ENUM_TIMEFRAMES period = PERIOD_M1)
  {
    _symbol = symbol;
    _period = period;
    _frameCount = 0;
    _warmUpCount = 0;

    _confAdaptation = 0.9;
    _stopMean = 20.0;
    _stopDev = 10.0;

    _confs = new nvVecd(5);

    // Save the time of the current bar so that we can start detecting new bars afterwards:
    datetime curTime[1];
    CHECK(CopyTime(_symbol, _period, 0, 1, curTime) == 1, "Cannot retrieve the time of the last bar");
    _last_bar_time = curTime[0];
  }

  void setWarmUp(ulong count)
  {
    _warmUpCount = count;
    _frameCount = 0;
  }

  bool isReady() const
  {
    return _frameCount > _warmUpCount;
  }

  ~nvStrategy()
  {
    logDEBUG("Deleting nvStrategy()");
    logDEBUG("Total num frames: " << _frameCount);

    delete _confs;
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

        _frameCount++;

        // Handle the new bar:
        handleNewBar(rates[0]);
      }
    }

    // On each tick we should update the stop lost if we are in a position.
    if (getCurrentPosition() != POSITION_NONE)
    {
      updateStopLost();
    }
  }

  void updateStopLost()
  {
    // We assume we are in a LONG or SHORT position:
    int pos = getCurrentPosition();
    CHECK(pos != POSITION_NONE, "Invalid none position.");

    // Retrieve the last tick info:
    MqlTick latest_price;
    CHECK(SymbolInfoTick(_symbol, latest_price), "Cannot retrieve last tick info.");

    // Check want is the best price we got so far:
    if (pos == POSITION_LONG)
    {
      // When in a long position, the best price is the max bid value observed:
      _best_price = MathMax(_best_price, latest_price.bid);
    }
    else
    {
      // Otherwise we are in short position, and in that case, the best price is the
      // minimum bid price observed.
      _best_price = MathMin(_best_price, latest_price.bid);
    }

    // Now compute the stop lost offset than we think we may apply:
    // This stop lost will depend on the smoothed confidence, the mean stoplost and the stoplost deviation:
    // it is given in number of pips.
    double ratio = _confs.EMA(_confAdaptation); // confidence value should always be between 0 and 1.

    // This stp value is the offset we want to apply from the best price in number of pips.
    double stp = _stopMean + _stopDev * (ratio - 0.5) * 2.0;

    // compute the new stop lost value we want to apply:
    double nstpval = NormalizeDouble(_best_price + stp * _Point * (pos == POSITION_LONG ? -1.0 : 1.0), _Digits);

    // Retrieve the current stop lost:
    double cur_stp = PositionGetDouble(POSITION_SL);

    // Update stop lost if applicable:
    // if (MathAbs(nstpval - cur_stp) > _Point)
    if ( (pos==POSITION_LONG && nstpval > cur_stp) || (pos==POSITION_SHORT && nstpval < cur_stp) )
    {
      // Send order to update stop lost:
      sendStopLostOrder(nstpval);
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

  void requestPosition(int pos, double confidence = 1.0)
  {
    // Add the new confidence value to the confidence vector:
    _confs.push_back(confidence);

    int cur_pos = getCurrentPosition();

    if(cur_pos!=pos)
    {
      // Need to close the previous position if applicable:
      if (cur_pos != POSITION_NONE)
      {
        logDEBUG("Closing position : " << cur_pos);
        closePosition();
      }

      if (pos != POSITION_NONE)
      {
        logDEBUG("Opening position : " << pos);
        double nlots = 1.0 * confidence;
        // Reset the confidence vector:
        _confs.fill(confidence);

        openPosition(pos, nlots);

      }
    }
  }

  bool openPosition(int pos, double lots)
  {
    CHECK(pos != POSITION_NONE, "Invalid non position to open.");

    return sendOrder(pos == POSITION_LONG ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, lots);
  }

  bool closePosition()
  {
    int cur_pos = getCurrentPosition();
    if (cur_pos == POSITION_NONE)
    {
      // Do nothing:
      return false;
    }

    ENUM_ORDER_TYPE otype = cur_pos == POSITION_LONG ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;

    double volume = PositionGetDouble(POSITION_VOLUME);
    return sendOrder(otype, volume);
  }

  bool sendStopLostOrder(double sl)
  {
    MqlTradeRequest tradeRequest;  // To be used for sending our trade requests
    MqlTradeResult tradeResult;    // To be used to get our trade results
    MqlTradeCheckResult checkResult;

    ZeroMemory(tradeRequest);
    tradeRequest.action = TRADE_ACTION_SLTP;                                  // immediate order execution
    tradeRequest.sl = sl; // Stop Loss
    tradeRequest.tp = 0.0; // Take Profit
    tradeRequest.symbol = _symbol;                                            // currency pair

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
    if (tradeResult.retcode != TRADE_RETCODE_DONE && tradeResult.retcode != TRADE_RETCODE_PLACED) //Request is completed or order placed
    {
      logERROR("The order request could not be completed code:" << tradeResult.retcode);
      ResetLastError();
      return false;
    }

    logDEBUG("Stop lost successfully updated to: " << sl);
    return true;
  }

  bool sendOrder(ENUM_ORDER_TYPE otype, double volume = 1.0, double price = -1.0)
  {
    MqlTradeRequest tradeRequest;  // To be used for sending our trade requests
    MqlTradeResult tradeResult;    // To be used to get our trade results
    MqlTradeCheckResult checkResult;

    CHECK(otype == ORDER_TYPE_BUY || otype == ORDER_TYPE_SELL, "Unsupported order type: " << (int)otype);

    MqlTick latest_price;
    CHECK(SymbolInfoTick(_symbol, latest_price), "Cannot retrieve the latest price.");

    // update the current best price:
    _best_price = latest_price.bid;

    if (price <= 0.0)
    {
      price = otype == ORDER_TYPE_BUY ? latest_price.ask : latest_price.bid;
    }

    double sl = price + _stopMean * _Point*(otype == ORDER_TYPE_BUY ? -1.0 : 1.0);

    ZeroMemory(tradeRequest);
    tradeRequest.action = TRADE_ACTION_DEAL;                                  // immediate order execution
    tradeRequest.price = NormalizeDouble(price, _Digits);          // latest ask price
    tradeRequest.sl = NormalizeDouble(sl,_Digits);                          // Stop Loss
    tradeRequest.tp = 0.0; // Take Profit
    tradeRequest.symbol = _symbol;                                            // currency pair
    tradeRequest.volume = volume;                                                 // number of lots to trade
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
    if (tradeResult.retcode != TRADE_RETCODE_DONE && tradeResult.retcode != TRADE_RETCODE_PLACED) //Request is completed or order placed
    {
      logERROR("The order request could not be completed  code:" << tradeResult.retcode);
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
