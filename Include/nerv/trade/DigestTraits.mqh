
#include <nerv/core.mqh>
#include <nerv/math.mqh>

/*
Base class representing the data that can be passed to the RRL model digest method.
*/
class nvDigestTraits : public nvObject
{
protected:
  double _closePrice;
  double _priceReturn;

public:
  /* Default constructor,
  assign default values.*/
  nvDigestTraits();

  /* Copy constructor, will copy the values from the original */
  nvDigestTraits(const nvDigestTraits &rhs);

  /* Assignment operator. */
  nvDigestTraits *operator=(const nvDigestTraits &rhs);

  /* Assign the last close price observed. */
  nvDigestTraits *closePrice(double val);

  /* Retrieve the last close price observed. */
  double closePrice() const;

  /* Retrieve the last price return computed from the latest close price and
  the previous close price. Note that this is only valid if isFirst() is returning false. */
  double priceReturn() const;

  /* Mark this instance as being a first value received. thus forcing any model
  using this input to discard the state computed with previous data. */
  nvDigestTraits *first();

  /* Check if this running instance is the first of a serie. */
  bool isFirst() const;
};


///////////////////////////////// implementation part ///////////////////////////////

nvDigestTraits::nvDigestTraits()
  : _closePrice(0.0),
    _priceReturn(0.0)
{
}

nvDigestTraits::nvDigestTraits(const nvDigestTraits &rhs)
{
  this = rhs;
}

nvDigestTraits *nvDigestTraits::operator=(const nvDigestTraits &rhs)
{
  _closePrice = rhs._closePrice;
  return GetPointer(this);
}

nvDigestTraits *nvDigestTraits::closePrice(double val)
{
  if (_closePrice != 0.0) {
    // The previous price is value, so we can compute a price return:
    _priceReturn = val - _closePrice;
  }

  _closePrice = val;
  return GetPointer(this);
}

double nvDigestTraits::closePrice() const
{
  return _closePrice;
}

double nvDigestTraits::priceReturn() const
{
  return _priceReturn;
}

nvDigestTraits *nvDigestTraits::first()
{
  _closePrice = 0.0;
  _priceReturn = 0.0;
  return GetPointer(this);
}

bool nvDigestTraits::isFirst() const
{
  return _closePrice==0.0;
}
