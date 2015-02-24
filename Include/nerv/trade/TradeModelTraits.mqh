
#include <nerv/core.mqh>
#include <nerv/math.mqh>

/*
Base class representing the data that can be passed to the RRL model class.
*/
class nvTradeModelTraits : public nvObject
{
protected:
  int _historyLength;
  string _id;

public:
  /* Default constructor,
  assign default values.*/
  nvTradeModelTraits();

  /* Copy constructor, will copy the values from the original */
  nvTradeModelTraits(const nvTradeModelTraits &rhs);

  /* Assignment operator. */
  nvTradeModelTraits *operator=(const nvTradeModelTraits &rhs);

  /* Check if we should keep history for this model. */
  bool keepHistory() const;

  /* Specify the length of the history to keep. 
    0 means no limit.
    -1 means no history. */
  nvTradeModelTraits *historyLength(int len);

  /* Retrieve the desired history length. */
  int historyLength() const;

  /* Assign an id to this model. */
  nvTradeModelTraits *id(string name);

  /* Retrieve the id assigned to this model. */
  string id() const;  
};


///////////////////////////////// implementation part ///////////////////////////////

nvTradeModelTraits::nvTradeModelTraits()
  : _historyLength(-1)
{
  _id = "";
}

nvTradeModelTraits::nvTradeModelTraits(const nvTradeModelTraits &rhs)
{
  this = rhs;
}

nvTradeModelTraits *nvTradeModelTraits::operator=(const nvTradeModelTraits &rhs)
{
  _historyLength = rhs._historyLength;
  _id = rhs._id;
  return GetPointer(this);
}

bool nvTradeModelTraits::keepHistory() const
{
  return _historyLength>=0;
}

nvTradeModelTraits *nvTradeModelTraits::historyLength(int len)
{
  _historyLength = len;
  return GetPointer(this);
}

int nvTradeModelTraits::historyLength() const
{
  return _historyLength;
}

nvTradeModelTraits *nvTradeModelTraits::id(string name)
{
  _id = name;
  return GetPointer(this);
}

string nvTradeModelTraits::id() const
{
  return _id;
}
