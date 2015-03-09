
#include <nerv/core.mqh>
#include <nerv/math.mqh>

/*
Base class representing the data that can be passed to the RRL model class.
*/
class nvBaseTraits : public nvObject
{
protected:
  int _historyLength;
  string _id;
  bool _autoWriteHistory;

public:
  /* Default constructor,
  assign default values.*/
  nvBaseTraits();

  /* Copy constructor, will copy the values from the original */
  nvBaseTraits(const nvBaseTraits &rhs);

  /* Assignment operator. */
  nvBaseTraits *operator=(const nvBaseTraits &rhs);

  /* Check if we should keep history for this model. */
  bool keepHistory() const;

  /* Specify the length of the history to keep. 
    0 means no limit.
    -1 means no history. */
  nvBaseTraits *historyLength(int len);

  /* Retrieve the desired history length. */
  int historyLength() const;

  /* Assign an id to this model. */
  nvBaseTraits *id(string name);

  /* Retrieve the id assigned to this model. */
  string id() const;  

  /* Assign the auto write history mode. */
  nvBaseTraits *autoWriteHistory(bool enable);

  /* Retrieve the auto write history mode. */
  bool autoWriteHistory() const;  
};


///////////////////////////////// implementation part ///////////////////////////////

nvBaseTraits::nvBaseTraits()
  : _historyLength(-1),
  _autoWriteHistory(false)
{
  _id = "";
}

nvBaseTraits::nvBaseTraits(const nvBaseTraits &rhs)
{
  this = rhs;
}

nvBaseTraits *nvBaseTraits::operator=(const nvBaseTraits &rhs)
{
  _historyLength = rhs._historyLength;
  _id = rhs._id;
  _autoWriteHistory = rhs._autoWriteHistory;
  return GetPointer(this);
}

bool nvBaseTraits::keepHistory() const
{
  return _historyLength>=0;
}

nvBaseTraits *nvBaseTraits::historyLength(int len)
{
  _historyLength = len;
  return GetPointer(this);
}

int nvBaseTraits::historyLength() const
{
  return _historyLength;
}

nvBaseTraits *nvBaseTraits::id(string name)
{
  _id = name;
  return GetPointer(this);
}

string nvBaseTraits::id() const
{
  return _id;
}

nvBaseTraits *nvBaseTraits::autoWriteHistory(bool enable)
{
  _autoWriteHistory = enable;
  return GetPointer(this);
}

bool nvBaseTraits::autoWriteHistory() const
{
  return _autoWriteHistory;
}
