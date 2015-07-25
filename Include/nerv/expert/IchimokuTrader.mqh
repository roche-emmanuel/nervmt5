#include <nerv/core.mqh>
#include <nerv/expert/PeriodTrader.mqh>
#include <nerv/math.mqh>

/*
This trader will implement a trader based on Ichimoku indicators
*/

class IchimokuTrader : public nvPeriodTrader
{
protected:
  double _riskLevel;
  double _contractSize;

  int _ichiHandle;
  double _tenkanVal[];
  double _kijunVal[];
  double _senkouAVal[];
  double _senkouBVal[];
  double _chinkouVal[];
  MqlRates _rates[];

public:
  IchimokuTrader(const nvSecurity& sec, ENUM_TIMEFRAMES period) : nvPeriodTrader(sec,period)
  {
    _ichiHandle=iIchimoku(_symbol,_period,9,26,52);
    CHECK(_ichiHandle>0,"Invalid Ichimoku handle");

    _riskLevel = 0.01;
    _contractSize = 100000.0;

    ArraySetAsSeries(_tenkanVal,true);
    ArraySetAsSeries(_kijunVal,true);
    ArraySetAsSeries(_senkouAVal,true);
    ArraySetAsSeries(_senkouBVal,true);
    ArraySetAsSeries(_chinkouVal,true);
    ArraySetAsSeries(_rates,true);
  }

  ~IchimokuTrader()
  {
    IndicatorRelease(_ichiHandle);
  }

  bool checkBuyConditions()
  {
    // We can only buy when the close price is above the cloud:
    if(_rates[0].close < _senkouAVal[0] || _rates[0].close < _senkouBVal[0])
    {
      return false;
    }

    // We must also ensure that tenkan sen line is above the kijun sen line at that time:
    if(_tenkanVal[0] <= _kijunVal[0])
    {
      return false;
    }

    return true;
    // TODO: we could also add a signal from the chinkou line here
  }

  bool checkSellConditions()
  {
    // We can only buy when the close price is above the cloud:
    if(_rates[0].close > _senkouAVal[0] || _rates[0].close > _senkouBVal[0])
    {
      return false;
    }

    // We must also ensure that tenkan sen line is above the kijun sen line at that time:
    if(_tenkanVal[0] >= _kijunVal[0])
    {
      return false;
    }

    return true;
    // TODO: we could also add a signal from the chinkou line here
  }

  void handleBar()
  {
    // retrieve the current ichimoku values:
    int num = 2;
    CHECK(CopyRates(_symbol,_period,1,30,_rates)==30,"Cannot copy the latest rates");
    CHECK(CopyBuffer(_ichiHandle,0,1,num,_tenkanVal)==num,"Cannot copy Ichimoku buffer 0");
    CHECK(CopyBuffer(_ichiHandle,1,1,num,_kijunVal)==num,"Cannot copy Ichimoku buffer 1");
    CHECK(CopyBuffer(_ichiHandle,2,1,4,_senkouAVal)==4,"Cannot copy Ichimoku buffer 2");
    CHECK(CopyBuffer(_ichiHandle,3,1,4,_senkouBVal)==4,"Cannot copy Ichimoku buffer 3");
    CHECK(CopyBuffer(_ichiHandle,4,1,30,_chinkouVal)==30,"Cannot copy Ichimoku buffer 4");

    MqlTick latest_price;
    CHECK(SymbolInfoTick(_symbol,latest_price),"Cannot retrieve latest price.")

    if(selectPosition())
    {
      // We just check if we should close the current position:
      // This should be done each time the tenkan sen line crosses the kijun sen line or if the price itself crosses the kijun sen line:
      if( (_tenkanVal[0]-_kijunVal[0])*(_tenkanVal[1]-_kijunVal[1]) <= 0.0)
      {
        logDEBUG(TimeCurrent()<<": Closing position due to tenkan <-> kijun cross.");
        closePosition();
      }
      else if ( (_rates[0].close - _kijunVal[0]) * (_rates[1].close - _kijunVal[1]) < 0.0)
      {
        logDEBUG(TimeCurrent()<<": Closing position due to price <-> kijun cross.")
        closePosition();
      }
      else {
        // Update the position stop lost each time the senkou span B line is flat.
        bool isflat = true;
        bool isBuy = PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
        double nsl = 0.0;

        for(int i = 1;i<4;++i)
        {
          double pval = isBuy ? MathMin(_senkouBVal[i-1],_senkouAVal[i-1]) : MathMax(_senkouBVal[i-1],_senkouAVal[i-1]);
          nsl = isBuy ? MathMin(_senkouBVal[i],_senkouAVal[i]) : MathMax(_senkouBVal[i],_senkouAVal[i]);

          isflat = isflat & pval==nsl;
        }

        if(isflat)
        {
          // actually update the stoploss:
          double sl = PositionGetDouble(POSITION_SL);
          if(isBuy && nsl > sl)
          {
            updateSLTP(nsl);
          }
          if(!isBuy && nsl < sl)
          {
            updateSLTP(nsl);
          }
        }
      }
    }
    else{
      // we use the the senkou span B line as worst case stop lost.

      // No position opened yet, check if we meet the buy or sell conditions:
      if(checkBuyConditions())
      {
        // Compute the size of the position we should take:
        double sl = MathMin(_senkouBVal[0],_senkouAVal[0]);
        double riskPoints = latest_price.ask - sl;
        double lot = computeLotSize(riskPoints);
        logDEBUG(TimeCurrent() <<": Entering LONG position at "<< latest_price.ask << " with " << lot << " lots, sl="<<sl<<", riskPoints="<<riskPoints)
        if(!sendDealOrder(ORDER_TYPE_BUY,lot,latest_price.ask,sl,0.0))
        {
          logERROR("Cannot place BUY order!");
        };
        return;
      }

      if(checkSellConditions())
      {
        // Compute the size of the position we should take:
        double sl = MathMax(_senkouBVal[0],_senkouAVal[0]);
        double riskPoints = sl - latest_price.bid ;
        double lot = computeLotSize(riskPoints);
        logDEBUG(TimeCurrent() <<": Entering SHORT position at "<< latest_price.bid << " with " << lot << " lots, sl="<<sl<<", riskPoints="<<riskPoints)
        if(!sendDealOrder(ORDER_TYPE_SELL,lot,latest_price.bid,sl,0.0))
        {
          logERROR("Cannot place SELL order!");
        };
        return;
      }
    }
  }

  double computeLotSize(double riskPoints)
  {
    // We do not want to risk more that X percent of our current balance
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double VaR = balance*_riskLevel;
    // We how that what we risk loosing in money is: p = l * riskPoints
    // Thus we should have:
    double lsize = VaR/(riskPoints*_contractSize);
    return normalizeLotSize(lsize); // This may return 0 if the risk tolerance is too low. 
  }

  double normalizeLotSize(double lot)
  {
    return MathFloor(lot*100)/100;
  }

  void handleTick()
  {

  }
};
