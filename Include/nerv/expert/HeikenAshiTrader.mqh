#include <nerv/core.mqh>
#include <nerv/expert/PeriodTrader.mqh>
#include <nerv/math.mqh>

/*
This trader will implement a trader based on Heiken Ashi indicators
and a moving average, in addition with a simple risk management layer.
*/

class HeikenAshiTrader : public nvPeriodTrader
{
protected:
  int _ma20Handle;
  int _ha4Handle;
  int _ha1Handle;

  double _ma20Val[];
  double _ha4Dir[];
  double _ha1Dir[];
  double _ha1High[];
  double _ha1Low[];
  double _ha1Open[];
  double _ha1Close[];

  double _trailingRatio;
  double _currentTarget;
  double _currentRiskPoints;
  double _slOffset;
  double _riskLevel;
  double _targetRatio;
  double _contractSize;
  double _spreadRatio;
  double _breakevenRatio;
  double _currentEntry;
  double _breakOffset;
  int _numDir;

public:
  HeikenAshiTrader(const nvSecurity& sec, ENUM_TIMEFRAMES period) : nvPeriodTrader(sec,period)
  {
    // Init the indicators:
    _ma20Handle=iMA(_symbol,_period,20,0,MODE_EMA,PRICE_CLOSE);
    _ha4Handle=iCustom(_symbol,PERIOD_H4,"nerv\\HeikenAshi");
    // _ha4Handle=iCustom(_symbol,PERIOD_D1,"nerv\\HeikenAshi");
    CHECK(_ha4Handle>0,"Invalid Heiken Ashi 4H handle")
    _ha1Handle=iCustom(_symbol,_period,"nerv\\HeikenAshi");
    CHECK(_ha1Handle>0,"Invalid Heiken Ashi 1H handle")

    // Trailing stop ratio:
    _trailingRatio = 0.5;
    _targetRatio = 2.0;
    _currentTarget = 0.0;
    _currentRiskPoints = 0.0;
    _slOffset = 10*_point;
    _spreadRatio = 2.0;
    _breakevenRatio = 0.3;
    _currentEntry = 0.0;
    _breakOffset = 5*_point;

    // Contract size for this account:
    _contractSize = 100000.0;

    // factor of risk on the current balance:
    _riskLevel = 0.01; // 0.01 is 1% of value at risk.

    _numDir = 4;
    ArrayResize(_ha1Dir,_numDir);
  }

  ~HeikenAshiTrader()
  {
    IndicatorRelease(_ma20Handle);
    IndicatorRelease(_ha4Handle);
    IndicatorRelease(_ha1Handle);
  }

  bool checkBuyConditions(double& sl)
  {
    // Check major trend:
    if(_ha4Dir[0]>0.5)
    {
      // The major trend is down, so we should not buy.
      return false;
    }

    // Check moving average slope:
    if(_ma20Val[0]>_ma20Val[1] || _ma20Val[1]>_ma20Val[2] || _ma20Val[2]>_ma20Val[3])
    {
      // MA trend is incorrect.
      return false;
    }

    // check that the first dir is correct, and then we have 2 down HA candles and then
    // again an up candle:
    bool sig = true;
    int inv1 = _numDir-2;
    int inv2 = _numDir-3;

    for(int i=0;i<_numDir;++i)
    {
      sig = sig & ( (i==inv1 || i==inv2) ? _ha1Dir[i]>0.5 : _ha1Dir[i]<0.5);
    }

    if(sig)
    {
      // This is a value signal, thus we should buy:
      sl = MathMin(_ha1Low[inv1],_ha1Low[inv2]);
      return true;
    }

    sig = true;
    for(int i=0;i<_numDir;++i)
    {
      sig = sig & ( i==inv1 ? _ha1Dir[i]>0.5 : _ha1Dir[i]<0.5);
    }

    if(sig)
    {
      // This is a value signal, thus we should buy:
      sl = _ha1Low[inv1];
      return true;
    }

    return false;
  }

  bool checkSellConditions(double& sl)
  {
    // Check major trend:
    if(_ha4Dir[0]<0.5)
    {
      // The major trend is down, so we should not buy.
      return false;
    }

    // Check moving average slope:
    if(_ma20Val[0]<_ma20Val[1] || _ma20Val[1]<_ma20Val[2] || _ma20Val[2]<_ma20Val[3])
    {
      // MA trend is incorrect.
      return false;
    }

    bool sig = true;
    int inv1 = _numDir-2;
    int inv2 = _numDir-3;

    for(int i=0;i<_numDir;++i)
    {
      sig = sig & ( (i==inv1 || i==inv2) ? _ha1Dir[i]<0.5 : _ha1Dir[i]>0.5);
    }

    // check that the first dir is correct, and then we have 2 down HA candles and then
    // again an up candle:
    if(sig)
    {
      // This is a value signal, thus we should buy:
      sl = MathMax(_ha1High[inv1],_ha1High[inv2]);
      return true;
    }

    sig = true;
    for(int i=0;i<_numDir;++i)
    {
      sig = sig & ( i==inv1 ? _ha1Dir[i]<0.5 : _ha1Dir[i]>0.5);
    }

    if(sig)
    {
      // This is a value signal, thus we should buy:
      sl = _ha1High[inv1];
      return true;
    }

    return false;
  }
  
  void handleBar()
  {
    // CHECK(CopyBuffer(_ha1Handle,0,1,1,_ha1Open)==1,"Cannot copy HA1 buffer 4");
    // CHECK(CopyBuffer(_ha1Handle,3,1,1,_ha1Close)==1,"Cannot copy HA1 buffer 4");
    // double dir = _ha1Open[0]<_ha1Close[0] ? 0.0 : 1.0;

    // logDEBUG(TimeCurrent()<<": HA1 dir: "<<dir)

    // When handling a new bar, we first check if we are already in a position or not:
    if(!selectPosition())
    {
      // If we are not in a position we check what the indicators tell us:
      // Retrieve the indicator values:
      CHECK(CopyBuffer(_ha4Handle,4,1,1,_ha4Dir)==1,"Cannot copy HA4 buffer 4");
      CHECK(CopyBuffer(_ma20Handle,0,1,_numDir,_ma20Val)==_numDir,"Cannot copy MA20 buffer 0");
      CHECK(CopyBuffer(_ha1Handle,0,1,_numDir,_ha1Open)==_numDir,"Cannot copy HA1 buffer 0");
      CHECK(CopyBuffer(_ha1Handle,1,1,_numDir,_ha1High)==_numDir,"Cannot copy HA1 buffer 1");
      CHECK(CopyBuffer(_ha1Handle,2,1,_numDir,_ha1Low)==_numDir,"Cannot copy HA1 buffer 2");  
      CHECK(CopyBuffer(_ha1Handle,3,1,_numDir,_ha1Close)==_numDir,"Cannot copy HA1 buffer 3");  
      
      for(int i=0;i<_numDir;++i)
      {
        _ha1Dir[i] = _ha1Open[i]<_ha1Close[i] ? 0.0 : 1.0;
      }

      // CHECK(CopyBuffer(_ha1Handle,4,0,4,_ha1Dir)==4,"Cannot copy HA1 buffer 4");

      double sl = 0.0;
      MqlTick latest_price;
      CHECK(SymbolInfoTick(_symbol,latest_price),"Cannot retrieve latest price.")

      // logDEBUG("Checking entry conditions...")

      // Check if we have buy conditions:
      if(checkBuyConditions(sl))
      {
        // Should place a buy order:
        // Check how many points we have at risk:
        sl -= _slOffset;

        // We also need to take the spread into account:
        // Otherwise we wont be able to place an order:
        double spread = latest_price.ask - latest_price.bid;
        _currentRiskPoints = MathMax(latest_price.ask - sl, _spreadRatio*spread);
        sl = latest_price.ask - _currentRiskPoints; // Update sl if needed.

        double lot = computeLotSize(_currentRiskPoints);
        _currentTarget = latest_price.ask + _currentRiskPoints*_targetRatio;

        _currentEntry = latest_price.ask;

        if(lot>0)
        {
          logDEBUG(TimeCurrent() <<": Entering LONG position at "<< latest_price.ask << " with " << lot << " lots, sl="<<sl<<", riskPoints="<<_currentRiskPoints)
          // logDEBUG("ha4Dir[0]="<<_ha4Dir[0]
          //   <<", ha1Dir[0]="<<_ha1Dir[0]
          //   <<", ha1Dir[1]="<<_ha1Dir[1]
          //   <<", ha1Dir[2]="<<_ha1Dir[2]
          //   <<", ha1Dir[3]="<<_ha1Dir[3]
          //   <<", maVal[0]="<<_ma20Val[0]
          //   <<", maVal[1]="<<_ma20Val[1]
          //   <<", maVal[2]="<<_ma20Val[2]
          //   <<", maVal[3]="<<_ma20Val[3]
          //   )
          if(!sendDealOrder(ORDER_TYPE_BUY,lot,latest_price.ask,sl,0.0))
          {
            logERROR("Cannot place BUY order!");
          };
          return;
        }
      }

      // Check if we have sell conditions:
      if(checkSellConditions(sl))
      {
        // Should place a buy order:
        // Check how many points we have at risk:
        sl += _slOffset;
        
        // We also need to take the spread into account:
        // Otherwise we wont be able to place an order:
        double spread = latest_price.ask - latest_price.bid;
        _currentRiskPoints = MathMax(sl-latest_price.bid, _spreadRatio*spread);
        sl = latest_price.bid + _currentRiskPoints; // Update sl if needed.

        double lot = computeLotSize(_currentRiskPoints);
        _currentTarget = latest_price.bid - _currentRiskPoints*_targetRatio;
        _currentEntry = latest_price.bid;

        if(lot>0)
        {
          logDEBUG(TimeCurrent() <<": Entering SHORT position at "<< latest_price.bid << " with " << lot << " lots, sl="<<sl<<", riskPoints="<<_currentRiskPoints)
          // logDEBUG("ha4Dir[0]="<<_ha4Dir[0]
          //   <<", ha1Dir[0]="<<_ha1Dir[0]
          //   <<", ha1Dir[1]="<<_ha1Dir[1]
          //   <<", ha1Dir[2]="<<_ha1Dir[2]
          //   <<", ha1Dir[3]="<<_ha1Dir[3]
          //   <<", maVal[0]="<<_ma20Val[0]
          //   <<", maVal[1]="<<_ma20Val[1]
          //   <<", maVal[2]="<<_ma20Val[2]
          //   <<", maVal[3]="<<_ma20Val[3]
          //   )          
          if(!sendDealOrder(ORDER_TYPE_SELL,lot,latest_price.bid,sl,0.0))
          {
            logERROR("Cannot place SELL order!");
          };
          return;
        }
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
    // if there is a position opened, we check if we need to update the trailing stop:
    if(selectPosition())
    {

      MqlTick latest_price;
      CHECK(SymbolInfoTick(_symbol,latest_price),"Cannot retrieve latest price.")
      double bid = latest_price.bid;
      double ask = latest_price.ask;

      double sl = PositionGetDouble(POSITION_SL);
      bool isBuy = PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;

      double trail = _currentRiskPoints*_trailingRatio;

      // double breakThrsPoints = MathAbs(_currentTarget-_currentEntry)*_breakevenRatio;
      // // check break even conditions:
      // if(isBuy && bid > (_currentEntry + breakThrsPoints) && breakThrsPoints > _breakOffset)
      // {
      //   // Ensure that we break even:
      //   double nsl = _currentEntry + _breakOffset;
      //   if(nsl > sl)
      //   {
      //     // logDEBUG("Applying LONG breakeven: nsl="<<nsl<<", bid="<<bid<<", ask="<<ask)
      //     updateSLTP(nsl);
      //   }
      // }

      // if(!isBuy && ask < (_currentEntry - breakThrsPoints) && breakThrsPoints > _breakOffset)
      // {
      //   // Ensure that we break even:
      //   double nsl = _currentEntry - _breakOffset;
      //   if(nsl < sl)
      //   {
      //     // logDEBUG("Applying SHORT breakeven: nsl="<<nsl<<", bid="<<bid<<", ask="<<ask)
      //     updateSLTP(nsl);
      //   }
      // }

      // If there is an open position then we also know how many points
      // we initially put at risk, and how many we targeted:
      if(isBuy)
      {
        // We check in which "risk zone" we are a try to lock additional profits if applicable:
        double nsl = _currentEntry + (MathFloor((bid - _currentEntry)/_currentRiskPoints) - 1.0)*_currentRiskPoints;
        if (nsl > sl)
        {
          // logDEBUG("Applying LONG trail: nsl="<<nsl<<", bid="<<bid<<", ask="<<ask)
          updateSLTP(nsl);
        }
      }
      else
      {
        double nsl = _currentEntry - (MathFloor((_currentEntry - ask)/_currentRiskPoints) - 1.0)*_currentRiskPoints;
        if (nsl < sl)
        {
          // logDEBUG("Applying SHORT trail: nsl="<<nsl<<", bid="<<bid<<", ask="<<ask)
          updateSLTP(nsl);
        }
      }
    } 
  }
};
