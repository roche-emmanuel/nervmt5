#include <nerv/core.mqh>
#include <nerv/expert/PeriodTrader.mqh>
#include <nerv/math.mqh>

/*
This trader will implement a simple MACD trading strategy.
*/

enum ENUM_PT_TREND
{
  TREND_NONE,
  TREND_LONG,
  TREND_SHORT
};

class MACDTrader : public nvPeriodTrader
{
protected:
  int _macdHandle;  // handle for our Moving Average indicator
  
  double _macdVal[];

  bool _initialized;
  nvVecd _macdSignals;
  double _macdMean;
  double _macdDev;
  nvVecd _prevSignals;
  double _macdMult;

public:
  MACDTrader(const nvSecurity& sec, ENUM_TIMEFRAMES period) : nvPeriodTrader(sec,period)
  {
    // Prepare the moving average indicator:
    _macdHandle=iMACD(_symbol,_period,4,20,3,PRICE_CLOSE);
    CHECK(_macdHandle>=0,"Invalid handle");

    // Not initialized by default:
    _initialized = false;
    _macdMean = 0.0;
    _macdDev = 0.0;
    _macdMult = 1.0;

    _macdSignals.resize(250);
    _prevSignals.resize(3);

    setRiskFactor(10.0);
  }

  ~MACDTrader()
  {
    logDEBUG("Deleting indicators...")
    IndicatorRelease(_macdHandle);
  }


  void updateStats(double macdSignal)
  {
    _macdSignals.push_back(macdSignal);
    _macdMean = _macdSignals.mean();
    _macdDev = _macdSignals.deviation();
  }

  void handleBar()
  {
    if(!_initialized)
    {
      logDEBUG("Initializing MACD trader...")

      // We retrieve the x previous values of the MACD signal
      // And we compute its mean and deviation:
      int len = (int)_macdSignals.size();
      CHECK(CopyBuffer(_macdHandle,1,1,len,_macdVal)==len,"Cannot copy MACD buffer 1");

      // Store the previous signal values:
      _prevSignals.push_back(_macdVal[len-3]);
      _prevSignals.push_back(_macdVal[len-2]);
      _prevSignals.push_back(_macdVal[len-1]);

      _macdSignals = _macdVal;
    }

    // Retrieve the latest signal value:
    CHECK(CopyBuffer(_macdHandle,1,0,1,_macdVal)==1,"Cannot copy MACD buffer 1");

    double signal = _macdVal[0];
    _prevSignals.push_back(signal);
    updateStats(signal);

    double prev_slope = _prevSignals[1] - _prevSignals[0];
    double slope = _prevSignals[2] - _prevSignals[1];

    if(selectPosition())
    {
      // There is currently a position opened:
      bool isBuy = PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
      if((isBuy && slope < 0.0) || (!isBuy && slope > 0.0))
      {
        // We should close this position:
        closePosition();
      }
    }

    // Update the risk aversion value depending on the current balance:
    updateRiskAversion();

    // check if there was a change in the signal orientation:
    MqlTick latest_price;
    CHECK(SymbolInfoTick(_symbol,latest_price),"Cannot retrieve latest price.")

    // check if we are in a good location to trigger a buy/sell order:
    if ( prev_slope*slope < 0.0 && MathAbs(signal - _macdMean) > (_macdMult+getRiskAversion()) * _macdDev ) 
    {
      if(slope > 0.0)
      {
        // Place a buy order:
        sendDealOrder(ORDER_TYPE_BUY,getLotSize(1.0),latest_price.ask,0.0,0.0);          
      }
      else
      {
        // Place a sell order:
        sendDealOrder(ORDER_TYPE_SELL,getLotSize(1.0),latest_price.bid,0.0,0.0);
      } 
    }
  }

  void handleTick()
  {
    // No op.
  }
};
