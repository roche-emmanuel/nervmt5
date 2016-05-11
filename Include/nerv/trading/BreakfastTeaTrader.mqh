#include <nerv/core.mqh>
#include <nerv/trading/SecurityTrader.mqh>

/*
Class: nvBreakfastTeaTrader

Base class representing an "English Breakfast Tea" trader 
*/
class nvBreakfastTeaTrader : public nvSecurityTrader {
protected:
  int _startHour;
  int _startMin;
  int _evalHour;
  int _evalMin;

  MqlRates _rates[];
  double _startPrice;

  double _deltaThreshold;

public:
  /*
    Class constructor.
  */
  nvBreakfastTeaTrader(string symbol, int startTime, int evalTime)
    : nvSecurityTrader(symbol)
  {
    CHECK(symbol=="GBPUSD","Invalid symbol for BreakfastTea Trader")
    logDEBUG("Creating BreakfastTeaTrader")

    _startHour = (int)floor(startTime/60);
    _startMin = startTime - _startHour*60;

    _evalHour = (int)floor(evalTime/60);
    _evalMin = evalTime - _evalHour*60;

    _startPrice = 0.0;
    _deltaThreshold = 0.0;
  }

  /*
    Class destructor.
  */
  ~nvBreakfastTeaTrader()
  {
    logDEBUG("Deleting RandomTrader")
  }

  virtual void handleBar()
  {
    // Retrieve the last bar:
    CHECK(CopyRates(_symbol,_period,1,1,_rates)==1,"Cannot copy the latest rates");

    MqlDateTime dts;
    datetime ctime = _rates[0].time;
    TimeToStruct(ctime,dts);

    if(dts.hour == _startHour && dts.min == _startMin) 
    {
      // If the last bar was the start time, we keep a ref on the start price:
      _startPrice = _rates[0].close;
     logDEBUG("Start price "<<_startPrice<< " at "<< ctime);
    }

    if(_startPrice > 0 && dts.hour == _evalHour && dts.min == _evalMin)
    {
      // Time to perform evaluation of the trade entry:
      double evalPrice = _rates[0].close;
      logDEBUG("Eval price "<<evalPrice<< " at "<< ctime);
 
      double delta = evalPrice - _startPrice;

      // Reset the start price:
      _startPrice = 0.0;

      double sl = 300.0*_psize;
      double tp = 300.0*_psize;
      double nlots = evaluateLotSize(300.0, 1.0);

      if(delta>_deltaThreshold)
      {
        openPosition(ORDER_TYPE_BUY,nlots,sl,tp);
      }
      else if(delta < _deltaThreshold)
      {
        openPosition(ORDER_TYPE_SELL,nlots,sl,tp);
      }
    }

    // At the end of the day we close the position if any:
    if(hasPosition() && dts.hour == 23)
    {
      logDEBUG("Forcing position close at "<<ctime);
      closePosition();
    }
  }
};
