
#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include "BaseTraits.mqh"

/*
Base class representing the data that can be passed to the RRL model class.
*/
class nvTradeModelTraits : public nvBaseTraits
{
protected:

public:
  /* Default constructor,
  assign default values.*/
  nvTradeModelTraits();

  /* Copy constructor, will copy the values from the original */
  nvTradeModelTraits(const nvTradeModelTraits &rhs);

  /* Assignment operator. */
  nvTradeModelTraits *operator=(const nvTradeModelTraits &rhs);
};


///////////////////////////////// implementation part ///////////////////////////////

nvTradeModelTraits::nvTradeModelTraits()
  : nvBaseTraits()
{
}

nvTradeModelTraits::nvTradeModelTraits(const nvTradeModelTraits &rhs)
{
  this = rhs;
}

nvTradeModelTraits *nvTradeModelTraits::operator=(const nvTradeModelTraits &rhs)
{
  nvBaseTraits::operator=(rhs);
  return GetPointer(this);
}
