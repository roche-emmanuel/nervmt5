
#include <nerv/trades.mqh>

/*
Base class representing the data that can be passed to the RRL model class.
*/
class nvRRLModelTraits : public nvTradeModelTraits
{
protected:
  int _numInputReturns;
  int _batchTrainLength;
  int _onlineTrainLength;

public:
  /* Default constructor,
  assign default values.*/
  nvRRLModelTraits();

  /* Copy constructor, will copy the values from the original */
  nvRRLModelTraits(const nvRRLModelTraits &rhs);

  /* Assignment operator. */
  nvRRLModelTraits *operator=(const nvRRLModelTraits &rhs); 

  /* Specify the number of price returns to use as input. */
  nvRRLModelTraits* numInputReturns(int num);

  /* Retrieve the number of price returns to use as input. */
  int numInputReturns() const;

  /* Assign the batch train length value. 
    default is -1 : no batch training performed in that case. */
  nvRRLModelTraits* batchTrainLength(int len);

  /* Retrieve the desired length for the batch training. */
  int batchTrainLength() const;

  /* Assign the online train length value. 
    default is -1 : no online training performed in that case. */
  nvRRLModelTraits* onlineTrainLength(int len);

  /* Retrieve the desired length for the batch training. */
  int onlineTrainLength() const;
};


///////////////////////////////// implementation part ///////////////////////////////

nvRRLModelTraits::nvRRLModelTraits()
  : _numInputReturns(10),
  _batchTrainLength(-1),
  _onlineTrainLength(100)
{
}

nvRRLModelTraits::nvRRLModelTraits(const nvRRLModelTraits &rhs)
 : nvTradeModelTraits(rhs)
{
  this = rhs;
}

nvRRLModelTraits *nvRRLModelTraits::operator=(const nvRRLModelTraits &rhs)
{
  nvTradeModelTraits::operator=(rhs);
  _numInputReturns = rhs._numInputReturns;
  _batchTrainLength = rhs._batchTrainLength;
  _onlineTrainLength = rhs._onlineTrainLength;
  return GetPointer(this);
}

nvRRLModelTraits* nvRRLModelTraits::batchTrainLength(int len)
{
  _batchTrainLength = len;
  return GetPointer(this);
}

int nvRRLModelTraits::batchTrainLength() const
{
  return _batchTrainLength;
}

nvRRLModelTraits* nvRRLModelTraits::numInputReturns(int num)
{
  _numInputReturns = num;
  return GetPointer(this);
}

int nvRRLModelTraits::numInputReturns() const
{
  return _numInputReturns;
}

nvRRLModelTraits* nvRRLModelTraits::onlineTrainLength(int len)
{
  _onlineTrainLength = len;
  return GetPointer(this);
}

int nvRRLModelTraits::onlineTrainLength() const
{
  return _onlineTrainLength;
}
