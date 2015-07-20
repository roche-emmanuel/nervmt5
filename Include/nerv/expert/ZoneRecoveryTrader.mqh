#include <nerv/core.mqh>
#include <nerv/expert/PeriodTrader.mqh>
#include <nerv/math.mqh>

/*
This trader will implement a simple version of the zone recovery trader.
*/

class ZoneRecoveryTrader : public nvPeriodTrader
{
protected:
  double _lotsize;
  double _targetProfit;
  double _zoneWidth;
  double _zoneLow;
  double _zoneHigh;
  double _lastEntry;
  double _prevSize;
  double _minGain;
  int _bounceCount;
  double _totalLost;

public:
  ZoneRecoveryTrader(const nvSecurity& sec, ENUM_TIMEFRAMES period) : nvPeriodTrader(sec,period)
  {
    _lotsize = 0.01;

    // Target profit in number of points:
    _targetProfit = 100.0*sec.getPoint();
    _zoneWidth = 40.0*sec.getPoint();
    _zoneLow = 0.0;
    _zoneHigh = 0.0;
    _lastEntry = 0.0;
    _minGain = 10.0*sec.getPoint();
    _bounceCount = 0;
    _totalLost = 0.0;
  }

  ~ZoneRecoveryTrader()
  {
  }

  void handleBar()
  {
  }

  double normalizeLotSize(double lot)
  {
    return MathMax(MathCeil(lot*100)/100,0.01);
  }

  void handleTick()
  {
    MqlTick latest_price;
    CHECK(SymbolInfoTick(_symbol,latest_price),"Cannot retrieve latest price.")
    double bid = latest_price.bid;

    if(selectPosition())
    {
      // We already have a position opened
      // We just need to monitor the crossing of the zone recovery borders.
      // Check what is the current position:
      bool isBuy = PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
      if(!isBuy && bid > _zoneHigh) 
      {
        // We need to invert the position and enter a buy!
        // So first we compute how much points we are about to loose:
        // Taking into account that we pay the ask price:
        double lost = (latest_price.ask - _lastEntry)*_prevSize;
        _totalLost += lost;

        closePosition();

        // Now open the buy position:
        // we will now want the take profit to be at:
        double tp = _zoneHigh + _targetProfit;
        _lastEntry = latest_price.ask;

        // and we want to compute the lot size to ensure we can cover the previous lost:
        // What we will get if successfull is (in points):
        // double gain = (tp - _lastEntry) * lotsize;
        // And we want this gain to cover the lost plus say 10 points:
        _prevSize = (_totalLost+_minGain)/(tp - _lastEntry);

        // round this to a value lot number:
        _prevSize = normalizeLotSize(_prevSize);
        _bounceCount++;

        logDEBUG(TimeCurrent() <<": Bounce " << _bounceCount <<": Entering LONG position at "<< _lastEntry << " with " << _prevSize << " lots. (totalLost: "<<_totalLost<<")")
        sendDealOrder(ORDER_TYPE_BUY,_prevSize,_lastEntry,0.0,tp);
      }
      if(isBuy && bid < _zoneLow) 
      {
        // We need to invert the position and enter a sell!
        // So first we compute how much points we are about to loose:
        // Taking into account that we pay the bid price:
        double lost = (_lastEntry - bid)*_prevSize;
        _totalLost += lost;

        closePosition();

        // Now open the buy position:
        // we want the take profit to be at:
        double tp = _zoneLow - _targetProfit;
        _lastEntry = bid;

        // and we want to compute the lot size to ensure we can cover the previous lost:
        // What we will get if successfull is (in points):
        // double gain = (tp - _lastEntry) * lotsize;
        // And we want this gain to cover the lost plus say 10 points:
        _prevSize = (_totalLost+_minGain)/(_lastEntry - tp);

        // round this to a value lot number:
        _prevSize = normalizeLotSize(_prevSize);
        _bounceCount++;

        logDEBUG(TimeCurrent() <<": Bounce " << _bounceCount <<": Entering SHORT position at "<< _lastEntry << " with " << _prevSize << " lots. (totalLost: "<<_totalLost<<")")
        sendDealOrder(ORDER_TYPE_SELL,_prevSize,_lastEntry,0.0,tp);
      }
    }
    else {
      // We place a new order, with a fixed takeprofit:
      sendDealOrder(ORDER_TYPE_SELL,_lotsize,bid,0.0,bid-_targetProfit);

      // Record the zone borders:
      _bounceCount = 0;
      _totalLost = 0.0;
      _zoneLow = bid;
      _zoneHigh = bid+_zoneWidth;
      _prevSize = _lotsize;
      _lastEntry = bid;
    }
  }
};
