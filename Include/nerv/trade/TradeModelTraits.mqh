
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
  bool _autoWriteHistory;

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

  /* Assign the auto write history mode. */
  nvTradeModelTraits *autoWriteHistory(bool enable);

  /* Retrieve the auto write history mode. */
  bool autoWriteHistory() const;  
};


///////////////////////////////// implementation part ///////////////////////////////

nvTradeModelTraits::nvTradeModelTraits()
  : _historyLength(-1),
  _autoWriteHistory(true)
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
  _autoWriteHistory = rhs._autoWriteHistory;
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

nvTradeModelTraits *nvTradeModelTraits::autoWriteHistory(bool enable)
{
  _autoWriteHistory = enable;
  return GetPointer(this);
}

bool nvTradeModelTraits::autoWriteHistory() const
{
  return _autoWriteHistory;
}
