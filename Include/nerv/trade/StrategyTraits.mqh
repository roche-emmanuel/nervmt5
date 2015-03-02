
#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include "BaseTraits.mqh"

/*
Base class representing the traits used for the configuration of a strategy object.
*/
class nvStrategyTraits : public nvBaseTraits
{
protected:
  string _symbol;
  ENUM_TIMEFRAMES _period;
  double _transactionCost;
  int _warmUpLength;
  int _signalMeanLength;
  double _signalAdaptation;
  double _signalThreshold;

public:
  /* Default constructor,
  assign default values.*/
  nvStrategyTraits();

  /* Copy constructor, will copy the values from the original */
  nvStrategyTraits(const nvStrategyTraits &rhs);

  /* Assignment operator. */
  nvStrategyTraits *operator=(const nvStrategyTraits &rhs);

  /* Assign the symbol that should be monitored by this strategy. */
  nvStrategyTraits *symbol(string sym);

  /* Retrieve the symbol monitored by this strategy. */
  string symbol() const;

  /* Assign the periodicity that should be used for this strategy. */
  nvStrategyTraits *period(ENUM_TIMEFRAMES period);

  /* Retrieve the periodicity used in this strategy. */
  ENUM_TIMEFRAMES period() const;

  /* Assign the transaction cost. */
  nvStrategyTraits *transactionCost(double cost);

  /* Retrieve the transaction cost. */
  double transactionCost() const;

  /* Specify the duration of the warmup phase.
  During that phase the strategy will ignore the model signal and not trade.*/
  nvStrategyTraits *warmUpLength(int len);

  /* Retrieve the desired length of the warmup phase. */
  int warmUpLength() const;

  /* Assign the signal mean vector length. */
  nvStrategyTraits* signalMeanLength(int len);

  /* Retrieve the signal mean vector length. */
  int signalMeanLength() const;

  /* Assign the signal adaptation value. */
  nvStrategyTraits* signalAdaptation(double coeff);

  /* Retrieve the signal adaptation value. */
  double signalAdaptation() const;

  /* Specify the signal threshold. */
  nvStrategyTraits* signalThreshold(double tau);

  /* Retrieve the signal threshold. */
  double signalThreshold() const;
};


///////////////////////////////// implementation part ///////////////////////////////

nvStrategyTraits::nvStrategyTraits()
  : _symbol("EURUSD"),
    _period(PERIOD_M1),
    _transactionCost(0.00001),
    _warmUpLength(0),
    _signalMeanLength(100),
    _signalAdaptation(0.01),
    _signalThreshold(0.0),
    nvBaseTraits()
{
}

nvStrategyTraits::nvStrategyTraits(const nvStrategyTraits &rhs)
{
  this = rhs;
}

nvStrategyTraits *nvStrategyTraits::operator=(const nvStrategyTraits &rhs)
{
  nvBaseTraits::operator=(rhs);
  _symbol = rhs._symbol;
  _period = rhs._period;
  _transactionCost = rhs._transactionCost;
  _warmUpLength = rhs._warmUpLength;
  _signalAdaptation = rhs._signalAdaptation;
  _signalMeanLength = rhs._signalMeanLength;
  _signalThreshold = rhs._signalThreshold;
  return THIS;
}

nvStrategyTraits *nvStrategyTraits::symbol(string sym)
{
  _symbol = sym;
  return THIS;
}

string nvStrategyTraits::symbol() const
{
  return _symbol;
}

nvStrategyTraits *nvStrategyTraits::period(ENUM_TIMEFRAMES period)
{
  _period = period;
  return THIS;
}

ENUM_TIMEFRAMES nvStrategyTraits::period() const
{
  return _period;
}

nvStrategyTraits *nvStrategyTraits::transactionCost(double cost)
{
  _transactionCost = cost;
  return THIS;
}

double nvStrategyTraits::transactionCost() const
{
  return _transactionCost;
}

nvStrategyTraits *nvStrategyTraits::warmUpLength(int len)
{
  _warmUpLength = len;
  return THIS;
}

int nvStrategyTraits::warmUpLength() const
{
  return _warmUpLength;
}

nvStrategyTraits* nvStrategyTraits::signalMeanLength(int len)
{
  _signalMeanLength = len;
  return THIS;
}

int nvStrategyTraits::signalMeanLength() const
{
  return _signalMeanLength;
}

nvStrategyTraits* nvStrategyTraits::signalAdaptation(double coeff)
{
  _signalAdaptation = coeff;
  return THIS;
}

double nvStrategyTraits::signalAdaptation() const
{
  return _signalAdaptation;
}

nvStrategyTraits* nvStrategyTraits::signalThreshold(double tau)
{
  _signalThreshold = tau;
  return THIS;
}

double nvStrategyTraits::signalThreshold() const
{
  return _signalThreshold;
}
