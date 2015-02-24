//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include <nerv/trade/Strategy_v0.mqh>
#include <nerv/trade/RRLModel.mqh>

class nvRRLStrategy : public nvStrategy_v0
{
protected:
  uint _numInputs;

  // length of the training phase:
  int _trainLen;

  // length of the eval phase:
  int _evalLen;

  nvVecd _train_returns;
  nvVecd _eval_returns;

  nvRRLModelBase* _model;

  nvVecd _params; // parameter vectors containing the price returns, the last position F and the intercept term.
  nvVecd _init_x;

  nvVecd _signals;

  double _last_price;

  // Counters for the phases:
  int _evalCount;

  // number of bars observed:
  long _barCount;

  double _tcost;

  // Current sharpe ratio used:
  double _SR;
  double _Rt;

public:
  nvRRLStrategy(double tcost, uint num, int train_len, int eval_len,
                string symbol, ENUM_TIMEFRAMES period = PERIOD_M1) :
    _numInputs(num),
    _train_returns(train_len),
    _eval_returns(num),
    _signals(train_len+1),
    _trainLen(train_len),
    _evalLen(eval_len),
    _model(NULL),
    _barCount(0),
    _last_price(0.0),
    _evalCount(0),
    _tcost(tcost),
    _SR(0.0),
    _Rt(0.0),
    nvStrategy_v0(symbol, period)
  {
    _useStopLoss = false;
    _init_x.resize(num+2);

    assignModel(new nvRRLModel(num,100));
  }

  nvRRLModelBase* getModel()
  {
    return _model;
  }

  ~nvRRLStrategy()
  {
    if(_model) {
      delete _model;
      _model = NULL;
    }
    //logDEBUG("Deleting nvRRLStrategy()");
  }

  void assignModel(nvRRLModelBase* model)
  {
    if(_model) {
      delete _model;
      _model = NULL;
    }

    _model = model;
  }
  
  void setMaxIterations(int num)
  {
    _model.setMaxIterations(num);
  }

  virtual void dryrun(nvVecd *prices, nvVecd *rets)
  {
    // perform a run on the provided returns:
    uint num = prices.size();
    _Rt = 0.0;
    _SR = 0.0;
    MqlRates rates;
    rates.close = prices[0];
    handleNewBar(rates);

    for (uint i = 1; i < num; ++i)
    {
      rates.close = prices[i];
      handleNewBar(rates);
  
      // Retrieve the latest return value:
      rets.push_back(_Rt);
    }

    CHECK(rets.size()==num-1,"Invalid return size!");
  }

  virtual void handleNewBar(const MqlRates &rates)
  {
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
      return;
    }

    if ((_evalCount % _evalLen) == 0)
    {
      performTraining();
      // reset evaluation count after training:
      _evalCount = 0;
    }

    _evalCount++;

    evaluate();
  }

  virtual double performTraining()
  {
    // perform the training:
    //double sr = _model.train(_tcost, GetPointer(_train_returns));
    _init_x.fill(1.0);
    //double cost = _model.train(_tcost, GetPointer(_train_returns));
    
    // trainigng limit signal conditions:
    double Fstart = _signals.front();
    double Fend = _signals.back();

    double cost = _model.train_cg(_tcost, Fstart, Fend, GetPointer(_init_x), GetPointer(_train_returns));
    
    _SR = -cost;
    //logDEBUG("Achieved SR=" << _SR << " on training.")
    // Return the achieved sharpe ratio on this training:
    return _SR;
  }

  virtual void addPriceReturn(double rt)
  {
    // add the new return value on the training vector:
    _train_returns.push_back(rt);
    _eval_returns.push_back(rt);
  }

  virtual void evaluate()
  {
    // Evaluation the model prediction:
    double Ft_1 = getCurrentPositionValue();
    //logDEBUG("Previous position value is : " << Ft_1);

		double Ft;
    _model.predict(GetPointer(_eval_returns), Ft_1, Ft);
    
    // Add the newly computed signal to the list:
    _signals.push_back(Ft);

    //logDEBUG("Predicting: Ft=" << Ft);

    double threshold = 0.1;
    int pid = (int)nv_sign_threshold(Ft, threshold);
    int npos = pid == 1 ? POSITION_LONG : pid == -1 ? POSITION_SHORT : POSITION_NONE;

    requestPosition(npos, (MathAbs(Ft) - threshold) / (1.0 - threshold));
  }
};
