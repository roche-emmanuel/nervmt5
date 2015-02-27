
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
  
public:
  /* Default constructor,
  assign default values.*/
  nvStrategyTraits();

  /* Copy constructor, will copy the values from the original */
  nvStrategyTraits(const nvStrategyTraits &rhs);

  /* Assignment operator. */
  nvStrategyTraits *operator=(const nvStrategyTraits &rhs);

  /* Assign the symbol that should be monitored by this strategy. */
  nvStrategyTraits* symbol(string sym);

  /* Retrieve the symbol monitored by this strategy. */
  string symbol() const;

  /* Assign the periodicity that should be used for this strategy. */
  nvStrategyTraits* period(ENUM_TIMEFRAMES period);

  /* Retrieve the periodicity used in this strategy. */
  ENUM_TIMEFRAMES period() const;

  /* Assign the transaction cost. */
  nvStrategyTraits *transactionCost(double cost);

  /* Retrieve the transaction cost. */
  double transactionCost() const;    
};


///////////////////////////////// implementation part ///////////////////////////////

nvStrategyTraits::nvStrategyTraits()
  : _symbol("EURUSD"),
  _period(PERIOD_M1),
  _transactionCost(0.00001),
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
  return THIS;
}

nvStrategyTraits* nvStrategyTraits::symbol(string sym)
{
  _symbol = sym;
  return THIS;
}

string nvStrategyTraits::symbol() const
{
  return _symbol;
}

nvStrategyTraits* nvStrategyTraits::period(ENUM_TIMEFRAMES period)
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
  return GetPointer(this);
}

double nvStrategyTraits::transactionCost() const
{
  return _transactionCost;
}
