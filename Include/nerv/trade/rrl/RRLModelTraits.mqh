
#include <nerv/core.mqh>
#include <nerv/math.mqh>

/*
Base class representing the data that can be passed to the RRL model class.
*/
class nvRRLModelTraits : public nvObject
{
protected:

public:
  /* Default constructor,
  assign default values.*/
  nvRRLModelTraits();

  /* Copy constructor, will copy the values from the original */
  nvRRLModelTraits(const nvRRLModelTraits &rhs);

  /* Assignment operator. */
  nvRRLModelTraits *operator=(const nvRRLModelTraits &rhs);
};


///////////////////////////////// implementation part ///////////////////////////////

nvRRLModelTraits::nvRRLModelTraits()
{
}

nvRRLModelTraits::nvRRLModelTraits(const nvRRLModelTraits &rhs)
{
  this = rhs;
}

nvRRLModelTraits *nvRRLModelTraits::operator=(const nvRRLModelTraits &rhs)
{
  return GetPointer(this);
}
