
#include <nerv/trade/RRLStrategyDry.mqh>
#include "RRLEMAModel.mqh"

class nvRRLEMAStrategyDry : public nvRRLStrategyDry
{
protected:
  double _Gt_1;
  int _maxEvalLen;
  nvVecd _SRValues;

public:
  nvRRLEMAStrategyDry(double tcost, uint num, int train_len, int eval_len,
                      string symbol, ENUM_TIMEFRAMES period = PERIOD_M1) :
    _Gt_1(0.0),
    _SRValues(1000),
    nvRRLStrategyDry(tcost, num, train_len, eval_len, symbol, period)
  {
    _maxEvalLen = eval_len;
    _init_x.resize(num+3);
  	nvRRLEMAModel* model = new nvRRLEMAModel(num,100);
    assignModel(model);
  }

  virtual double performTraining()
  {
    nvRRLStrategyDry::performTraining();

    // Update the evaluation duration with the estimation from the model:
    double est = ((nvRRLEMAModel*)getModel()).getEvaluationEstimate();
    est = MathMin(est,_maxEvalLen);
    
    _evalLen = (int)MathFloor(est+0.5);
    CHECK(_evalLen>0,"Invalid evaluation duration.");
    logDEBUG("Using evaluation duration: "<<_evalLen);
    return _SR;
  }


  virtual void evaluate()
  {
    // Evaluation the model prediction:
    double Ft;
    _Gt_1 = _model.predict(GetPointer(_eval_returns), _Gt_1, Ft);
    //logDEBUG("Predicting: Ft="<<Ft <<" with Gt="<<_Gt_1);

    _SRValues.push_back(_SR);

    // Retrieve the current max:
    double srmax = _SRValues.max();

    if(_SR<0.01 || _SR<(srmax*0.75)) {
      // We do not trade at all if the previous sharpe ratio is too low:
      Ft = 0.0;
    }

    if(_evalLen<_maxEvalLen/2.0)
    {
      // Do not trade if the signal is current unstable.
      Ft = 0.0;
    }

    // Add the newly computed signal to the list:
    _signals.push_back(Ft);

    // Compute the Rt value:
    double rt = _eval_returns.back();
    _Rt = _Ft_1 * rt - _tcost * MathAbs(Ft - _Ft_1);
    
    _wealth += _Rt;
    _Ft_1 = Ft;
  }
};
