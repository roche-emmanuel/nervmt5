
#include <nerv/trade/RRLStrategyDry.mqh>

class nvRRLStrategyPerfect : public nvRRLStrategyDry
{
protected:
  nvVecd _actual_returns;

public:
  nvRRLStrategyPerfect(double tcost, uint num, int train_len, int eval_len,
                string symbol, ENUM_TIMEFRAMES period = PERIOD_M1) :
    _actual_returns(train_len),
    nvRRLStrategyDry(tcost,num,train_len,eval_len,symbol,period)
  {
  }

  ~nvRRLStrategyPerfect()
  {
    logDEBUG("Deleting nvRRLStrategyPerfect()");
  }

  virtual void handleNewBar(const MqlRates &rates)
  {
     _pricesWriter.add(rates.close);

    if (_last_price <= 0.0)
    {
      _last_price = rates.close;
      return; // do nothing more this time.
    }

    // A new bar is received, so we use the previous price to compute the new return value:
    double rt = rates.close - _last_price;
    _last_price = rates.close;

    // Apply leverage:
    //rt *= 100.0;

    addPriceReturn(rt);

    _barCount++;
    if (_barCount < _trainLen)
    {
      // We don't have enough training bars yet, so we don't do anything anymore.
      
      _signalWriter.add(_Ft_1);
      _wealthWriter.add(_wealth);
      return;
    }

    if((_barCount % _trainLen)==0)
    {
      double psr = performTraining();

      // Now we can start the evaluation with the trained data:
      for(int i=0; i<_trainLen;++i) {
        _eval_returns.push_back(_train_returns[i]);
        _evalCount++;
        if(_evalCount<(int)_eval_returns.size())
        {
          // We don't have enough evaluations yet.
          continue;
        }

        evaluate();
      }

      // We are done with evaluation, now compute the actual sharpe ratio observed:
      double A = _actual_returns.mean();
      double B = _actual_returns.norm2()/_actual_returns.size();
      double sr = A/sqrt(B-A*A);
      double sdev = sr-psr;
      logDEBUG("Observed Sharpe ratio: sr="<<sr<<", deviation from prediction: dev="<<sdev);
    }
  }

  virtual void addPriceReturn(double rt)
  {
    _train_returns.push_back(rt);
    _returnsWriter.add(rt);
    _sharpeWriter.add(_SR);
  }

  virtual void evaluate()
  {
    // Evaluation the model prediction:
    double Ft = _Ft_1;
    _model.predict(GetPointer(_eval_returns),_Ft_1,Ft);
    //logDEBUG("Predicting: Ft="<<Ft);

    // Compute the Rt value:
    double rt = _eval_returns.back();
    double Rt = _Ft_1 *rt - _tcost * MathAbs(Ft - _Ft_1);
    _actual_returns.push_back(Rt);
    _wealth += Rt;

    _Ft_1 = Ft;
    
    _signalWriter.add(_Ft_1);  
    _wealthWriter.add(_wealth);
  }
};
