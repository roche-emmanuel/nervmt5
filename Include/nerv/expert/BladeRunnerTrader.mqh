#include <nerv/core.mqh>
#include <nerv/expert/PeriodTrader.mqh>

/*
Trading strategy based on the descriptino found on the page:
http://www.authenticfx.com/free-forex-trading-strategy.html
*/

enum ENUM_BR_BIAS
{
  BIAS_NONE,
  BIAS_LONG,
  BIAS_SHORT
};

class BladeRunnerTrader : public nvPeriodTrader
{
protected:
  int _maHandle;  // handle for our Moving Average indicator
  double _maVal[]; // Dynamic array to hold the values of Moving Average for each bars
  MqlRates _mrate[];

  ENUM_BR_BIAS _bias;
  bool _signaled;
  double _margin;
  int _TKP;
  double _lot;
  double _currentBase;
  double _currentHigh;
  double _currentLow;

public:
  BladeRunnerTrader(const nvSecurity& sec, ENUM_TIMEFRAMES period) : nvPeriodTrader(sec,period)
  {
    // Prepare the moving average indicator:
    int ma_period = 20;
    _maHandle=iMA(_security.getSymbol(),_period,ma_period,0,MODE_EMA,PRICE_CLOSE);
    
    //--- What if handle returns Invalid Handle    
    CHECK(_maHandle>=0,"Invalid indicators handle");

    // the rates arrays
    ArraySetAsSeries(_mrate,true);
    // the MA-20 values arrays
    ArraySetAsSeries(_maVal,true);

    // Initialize the bias:
    _bias = BIAS_NONE;

    // Security margin to consider in terms of points around the EMA value:
    _margin = 400;

    // Take profit level:
    _TKP = 1000;

    // Lot size:
    _lot = 0.1;
  }

  ~BladeRunnerTrader()
  {
    logDEBUG("Deleting indicators...")
    
    //--- Release our indicator handles
    IndicatorRelease(_maHandle);
  }

  void handleBar()
  {
    string symbol = _security.getSymbol();

    // MqlTick latest_price;
    MqlTick latest_price;
    CHECK(SymbolInfoTick(symbol,latest_price),"Cannot retrieve latest price.")

    // Get the details of the latest 3 bars
    CHECK(CopyRates(symbol,_period,0,3,_mrate)==3,"Cannot copy the latest rates");
    CHECK(CopyBuffer(_maHandle,0,0,3,_maVal)==3,"Cannot copy MA buffer 0");

    double prev_ema = _maVal[0];
    double point = _security.getPoint();
    int digits = _security.getDigits();

    // If we currently have a position opened, we use the EMA20 value to update the stop loss if possible:
    if(selectPosition())
    {
      double stoploss = PositionGetDouble(POSITION_SL);
      bool isBuy = PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
      double nsl = isBuy ? MathMax(prev_ema,stoploss) : MathMin(prev_ema,stoploss);
      if(nsl!=stoploss) {

        updateSLTP(nsl);
      }
      return;
    }

    double pclose = _mrate[0].close;
    // logDEBUG("pclose="<<pclose<<", prev_ema="<<prev_ema)
    // logDEBUG("delta="<<NormalizeDouble(pclose-prev_ema,digits))

    // There is currently no position opened, so we check if we should open one:
    if (_bias == BIAS_NONE) {
      // Select our current bias depending on the current price location:
      if (pclose > (prev_ema + _margin*point))
      {
        // It seems prices are going up:
        _bias = BIAS_LONG;
        _currentBase = prev_ema;
        _currentHigh = pclose;
        logDEBUG("Detected LONG bias.")
      }

      if (pclose < (prev_ema - _margin*point))
      {
        // It seems prices are going down:
        _bias = BIAS_SHORT;
        _currentBase = prev_ema;
        _currentLow = pclose;
        logDEBUG("Detected SHORT bias.")
      }
    }

    double fallbackRatio = 0.5;

    if (_bias == BIAS_LONG)
    {
      if (pclose > _currentHigh)
      {
        // update the references:
        _currentHigh = pclose;
        _currentBase = prev_ema;
      }

      // If the price goes down too much we cancel the bias:
      if (pclose < prev_ema)
      {
        logDEBUG("Cancelling LONG bias.")
        _bias = BIAS_NONE;
        _signaled = false;
        return; // do nothing more.
      }

      if (_signaled) {
        // We already got a signal candlestick, so we check if the previous candlestick confirmed that signal:
        // To get a confirmation we would expect the close price of the previous stick to be higher than the close of the 
        // stick before it:
        if(pclose>_mrate[1].close) {
          // This is a confirmation of the signal, so we should place a buy order:
          // TODO: place a pending order instead ?
          double price = latest_price.ask;
          double sl = prev_ema;
          double tp = 0.0; //latest_price.ask+ _TKP*point;

          logDEBUG("Placing buy order")
          sendDealOrder(ORDER_TYPE_BUY,_lot,price,sl,tp);
        }
        else {
          // cancel this signal:
          logDEBUG("Cancelling LONG signal.")
          _signaled = false;
        }
      }
      else {
        // We didn't get any signal yet, check the previous bar:
        // double thres = (prev_ema+_margin*point*0.25);
        // if(_mrate[0].low < thres && pclose > thres && pclose > _mrate[0].open)
        // {
        //   logDEBUG("Detected LONG signal.")
        //   _signaled = true;
        // }

        // We consider we get a signal when we fall by 75% from the current High:
        if((pclose - _currentBase)/(_currentHigh - _currentBase) < fallbackRatio)
        {
          logDEBUG("Detected LONG signal.")
          _signaled = true;
        }
      }
    }

    if (_bias == BIAS_SHORT)
    {
      if (pclose < _currentLow)
      {
        // update the references:
        _currentLow = pclose;
        _currentBase = prev_ema;
      }


      // If the price goes down too much we cancel the bias:
      if (pclose > prev_ema)
      {
        logDEBUG("Cancelling SHORT bias.")
        _bias = BIAS_NONE;
        _signaled = false;
        return; // do nothing more.
      }

      if (_signaled) {
        // We already got a signal candlestick, so we check if the previous candlestick confirmed that signal:
        // To get a confirmation we would expect the close price of the previous stick to be higher than the close of the 
        // stick before it:
        if(pclose<_mrate[1].close) {
          // This is a confirmation of the signal, so we should place a buy order:
          // TODO: place a pending order instead ?
          double price = latest_price.bid;
          double sl = prev_ema;
          double tp = 0.0; //latest_price.bid - _TKP*point;

          logDEBUG("Placing sell order")
          sendDealOrder(ORDER_TYPE_SELL,_lot,price,sl,tp);
        }
        else {
          // cancel this signal:
          logDEBUG("Cancelling SHORT signal.")
          _signaled = false;
        }
      }
      else {
        // We didn't get any signal yet, check the previous bar:
        // double thres = (prev_ema-_margin*point*0.25);
        // if(_mrate[0].high > thres && pclose < thres && pclose < _mrate[0].open)
        // {
        //   logDEBUG("Detected SHORT signal.")
        //   _signaled = true;
        // }

        // We consider we get a signal when we fall by 75% from the current High:
        if((_currentBase - pclose)/(_currentBase - _currentLow) < fallbackRatio)
        {
          logDEBUG("Detected SHORT signal.")
          _signaled = true;
        }        
      }
    }
  }
};
