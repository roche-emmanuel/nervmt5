
#include <nerv/trade/RRLStrategy.mqh>
#include <nerv/math/VectorWriter.mqh>

class nvRRLStrategyDry : public nvRRLStrategy
{
protected:
  nvVectorWriter _pricesWriter;
  nvVectorWriter _returnsWriter;
  nvVectorWriter _wealthWriter;
  nvVectorWriter _signalWriter;
  nvVectorWriter _sharpeWriter;

  double _Ft_1;
  double _wealth;

public:
  nvRRLStrategyDry(double tcost, uint num, int train_len, int eval_len,
                string symbol, ENUM_TIMEFRAMES period = PERIOD_M1) :
    _pricesWriter("eur_prices.txt"),
    _returnsWriter("eur_returns.txt"),
    _wealthWriter("eur_wealth.txt"),
    _signalWriter("eur_signal.txt"),
    _sharpeWriter("eur_sharpe.txt"),
    _Ft_1(0.0),
    _wealth(0.0),
    nvRRLStrategy(tcost,num,train_len,eval_len,symbol,period)
  {
  }

  virtual void handleNewBar(const MqlRates &rates)
  {
    _pricesWriter.add(rates.close);
    nvRRLStrategy::handleNewBar(rates);
  }

  virtual void addPriceReturn(double rt)
  {
    nvRRLStrategy::addPriceReturn(rt);
    _returnsWriter.add(rt);
    _wealthWriter.add(_wealth);
    _signalWriter.add(_Ft_1);
    _sharpeWriter.add(_SR);
  }

  virtual void evaluate()
  {
    // Evaluation the model prediction:
    double Ft = _model.predict(GetPointer(_eval_returns),_Ft_1);
    //logDEBUG("Predicting: Ft="<<Ft);

    // Compute the Rt value:
    double rt = _eval_returns.back();
    _Rt = _Ft_1 *rt - _tcost * MathAbs(Ft - _Ft_1);
    _wealth += _Rt;
    _Ft_1 = Ft;
  }
};
