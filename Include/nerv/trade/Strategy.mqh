#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include <nerv/trades.mqh>

enum PositionType
{
  POSITION_NONE,
  POSITION_LONG,
  POSITION_SHORT
};

/* Class used as a base for the implementation of trading strategies. */
class nvStrategy : public nvObject
{
protected:
  nvStrategyTraits _traits;

  datetime _last_bar_time;

  nvDigestTraits _digestTraits;
  nvTradeModel *_model;

  /* A strategy should also have an history map to
  keep track of the actual wealth and returns that we get. */
  nvHistoryMap _history;

  /* Current position we currently have:
   This value should instead be integrated into a transaction handler component.
   The current position should always be -1 (short), 0 (none) or 1 (long) */
  double _currentPosition;

  /* Current wealth of this agent. */
  double _currentWealth;

public:
  /* Constructor taking the strategy traits.*/
  nvStrategy(const nvStrategyTraits &traits);

  /* Destructor will release the model is any. */
  ~nvStrategy();

  /* Method that should be called externally each time a new tick is received. */
  virtual void handleTick();

  /* Method to handle a new bar creation event. */
  virtual void handleBar(const MqlRates &rates, ulong elapsed, nvTradePrediction &pred);

  /* Assign a model instance to this strategy object. */
  void setModel(nvTradeModel *model);

  /* Retrieve the model assigned to this strategy. */
  nvTradeModel *getModel() const;

  /* Method used to perform a dryrun of this strategy given a vector of input prices. */
  virtual void dryrun(const nvVecd &prices);

  /* Method used to retrieve the current position we are currently in. */
  virtual double getCurrentPosition();

  /* Retrieve the history map for this strategy. */
  virtual nvHistoryMap* getHistoryMap();
};


nvStrategy::nvStrategy(const nvStrategyTraits &traits)
  : _currentPosition(0.0),
  _currentWealth(0.0)
{
  _traits = traits;

  _history.setPrefix(_traits.id() == "" ? "" : (_traits.id() + "_"));
  _history.setAutoWrite(_traits.autoWriteHistory());

  if (_traits.historyLength() != _history.getSize())
  {
    // Need to reset the history:
    _history.setSize(_traits.historyLength());
    _history.clear();
  }

  // Save the time of the current bar so that we can start detecting new bars afterwards:
  datetime curTime[1];
  CHECK(CopyTime(_traits.symbol(), _traits.period(), 0, 1, curTime) == 1, "Cannot retrieve the time of the last bar");
  _last_bar_time = curTime[0];
}

nvStrategy::~nvStrategy()
{
  RELEASE_PTR(_model);
}

void nvStrategy::handleTick()
{
  datetime curTime[1];

  // copying the last bar time to the element New_Time[0]
  CHECK(CopyTime(_traits.symbol(), _traits.period(), 0, 1, curTime) == 1, "Cannot retrieve the time of the last bar");

  if (_last_bar_time != curTime[0])
  {
    CHECK(curTime[0] > _last_bar_time, "Going back in time " << curTime[0] << "<" << _last_bar_time);

    ulong diff = curTime[0] - _last_bar_time;
    _last_bar_time = curTime[0];

    // Ensure the time delta is correct:
    ulong tdelta = getBarDuration(_traits.period());
    CHECK(diff % tdelta == 0, "Unexpected bar delta difference, diff=" << diff << " bar duration: " << tdelta);

    // Handle the new bar:
    MqlRates rates[1];
    CHECK(CopyRates(_traits.symbol(), _traits.period(), 0, 1, rates) == 1, "Cannot copy new rates");

    double confidence = 0.0;
    nvTradePrediction pred;
    handleBar(rates[0], diff, pred);
  }
}

void nvStrategy::handleBar(const MqlRates &rates, ulong elapsed, nvTradePrediction &pred)
{
  CHECK(_model != NULL, "Invalid model.");

  _digestTraits.closePrice(rates.close);
  bool valid = _model.digest(_digestTraits, pred);

  // Retrieve the current position:
  double Ft_1 = (double)getCurrentPosition();

  // Compute the default return value:
  // We assume that there is no change in the agent position
  // So there is no transaction cost evolved by default:
  double rt = _digestTraits.priceReturn();
  double Rt = Ft_1*rt; 

  // If the prediction is valid then we can use it to actually compute a return:
  if (valid && _digestTraits.barCount()>_traits.warmUpLength()) {
    // Retrieve the current signal which is predicted.
    double Ft = pred.signal();
	
		// We cannot use "partial" transactions, so we need to ensure Ft
		// is either -1, 0 or 1:
		//Ft = Ft > 0.5 ? 1.0 : Ft < -0.5 ? -1.0 : 0.0;
		
    // Compute the return according to the model:
    // TODO: we could use the actual transaction cost instead here (retrieve the spread from the latest bar)
    double tcost = _traits.transactionCost();

    Rt = Ft_1*rt - tcost * MathAbs(Ft - Ft_1);

    // Assign the new position:
    // _currentPosition = Ft > 0.5 ? 1 : Ft < -0.5 ? -1 : 0;
    _currentPosition = Ft;
  }

  // Add the Return to the total wealth:
  _currentWealth += Rt;

  // Write the history if required:
  if (_traits.keepHistory()) {
    _history.add("strategy_returns", Rt);

    // And compute the total wealth:
    _history.add("strategy_wealth", _currentWealth);
  }
}

void nvStrategy::setModel(nvTradeModel *model)
{
  RELEASE_PTR(_model);
  _model = model;
}

nvTradeModel *nvStrategy::getModel() const
{
  return _model;
}

void nvStrategy::dryrun(const nvVecd &prices)
{
  // perform a run on the provided returns:
  uint num = prices.size();

  CHECK(num > 2, "Invalid size for prices vector.");

  MqlRates rates;
  rates.close = prices[0];

  ulong elapsed = getBarDuration(_traits.period());
  nvTradePrediction pred;

  // initialization:
  handleBar(rates, elapsed, pred);

  for (uint i = 1; i < num; ++i)
  {
    rates.close = prices[i];
    handleBar(rates, elapsed, pred);
  }
}

double nvStrategy::getCurrentPosition()
{
  return _currentPosition;
}

nvHistoryMap* nvStrategy::getHistoryMap()
{
  return GetPointer(_history);
}
