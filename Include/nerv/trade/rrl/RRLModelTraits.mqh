
#include <nerv/core.mqh>
#include <nerv/math.mqh>

/*
Base class representing the data that can be passed to the RRL model class.
*/
class nvRRLModelTraits : public nvObject
{
protected:
  int _historyLength;
  string _id;

public:
  /* Default constructor,
  assign default values.*/
  nvRRLModelTraits();

  /* Copy constructor, will copy the values from the original */
  nvRRLModelTraits(const nvRRLModelTraits &rhs);

  /* Assignment operator. */
  nvRRLModelTraits *operator=(const nvRRLModelTraits &rhs);

  /* Check if we should keep history for this model. */
  bool keepHistory() const;

  /* Specify the length of the history to keep. 
    0 means no limit.
    -1 means no history. */
  nvRRLModelTraits *historyLength(int len);

  /* Retrieve the desired history length. */
  int historyLength() const;

  /* Assign an id to this model. */
  nvRRLModelTraits *id(string name);

  /* Retrieve the id assigned to this model. */
  string id() const;  
};


///////////////////////////////// implementation part ///////////////////////////////

nvRRLModelTraits::nvRRLModelTraits()
  : _historyLength(-1)
{
  _id = "";
}

nvRRLModelTraits::nvRRLModelTraits(const nvRRLModelTraits &rhs)
{
  this = rhs;
}

nvRRLModelTraits *nvRRLModelTraits::operator=(const nvRRLModelTraits &rhs)
{
  _historyLength = rhs._historyLength;
  _id = rhs._id;
  return GetPointer(this);
}

bool nvRRLModelTraits::keepHistory() const
{
  return _historyLength>=0;
}

nvRRLModelTraits *nvRRLModelTraits::historyLength(int len)
{
  _historyLength = len;
  return GetPointer(this);
}

int nvRRLModelTraits::historyLength() const
{
  return _historyLength;
}

nvRRLModelTraits *nvRRLModelTraits::id(string name)
{
  _id = name;
  return GetPointer(this);
}

string nvRRLModelTraits::id() const
{
  return _id;
}
