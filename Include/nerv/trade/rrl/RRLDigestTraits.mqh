
#include <nerv/core.mqh>
#include <nerv/math.mqh>

/*
Base class representing the data that can be passed to the RRL model digest method.
*/
class nvRRLDigestTraits : public nvObject
{
protected:
  double _closePrice;
  double _isFirst;
  double _priceReturn;

public:
  /* Default constructor,
  assign default values.*/
  nvRRLDigestTraits();

  /* Copy constructor, will copy the values from the original */
  nvRRLDigestTraits(const nvRRLDigestTraits &rhs);

  /* Assignment operator. */
  nvRRLDigestTraits *operator=(const nvRRLDigestTraits &rhs);

  /* Assign the last close price observed. */
  nvRRLDigestTraits *closePrice(double val);

  /* Retrieve the last close price observed. */
  double closePrice() const;

  /* Retrieve the last price return computed from the latest close price and
  the previous close price. Note that this is only valid if isFirst() is returning false. */
  double priceReturn() const;

  /* Mark this instance as being a first value received. thus forcing any model
  using this input to discard the state computed with previous data. */
  nvRRLDigestTraits *first();

  /* Check if this running instance is the first of a serie. */
  bool isFirst() const;
};


///////////////////////////////// implementation part ///////////////////////////////

nvRRLDigestTraits::nvRRLDigestTraits()
  : _closePrice(0.0),
    _isFirst(true),
    _priceReturn(0.0)
{
}

nvRRLDigestTraits::nvRRLDigestTraits(const nvRRLDigestTraits &rhs)
{
  this = rhs;
}

nvRRLDigestTraits *nvRRLDigestTraits::operator=(const nvRRLDigestTraits &rhs)
{
  _closePrice = rhs._closePrice;
  _isFirst = rhs._isFirst;
  return GetPointer(this);
}

nvRRLDigestTraits *nvRRLDigestTraits::closePrice(double val)
{
  if (_closePrice != 0.0) {
    // The previous price is value, so we can compute a price return:
    _isFirst = false;
    _priceReturn = val - _closePrice;
  }

  _closePrice = val;
  return GetPointer(this);
}

double nvRRLDigestTraits::closePrice() const
{
  return _closePrice;
}

double nvRRLDigestTraits::priceReturn() const
{
  return _priceReturn;
}

nvRRLDigestTraits *nvRRLDigestTraits::first()
{
  _isFirst = true;
  _closePrice = 0.0;
  _priceReturn = 0.0;
  return GetPointer(this);
}

bool nvRRLDigestTraits::isFirst() const
{
  return _isFirst;
}
