
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
  int _returnsMeanLength;
  double _transactionCost;

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

  /* Assign the transaction cost. */
  nvRRLModelTraits *transactionCost(double cost);

  /* Retrieve the transaction cost. */
  double transactionCost() const;  

  /* Assign the length of the vector that will be used
    for the computation of the returns mean and deviation. */
  nvRRLModelTraits* returnsMeanLength(int len);

  /* Retrieve the desired length for the returns mean computation. */
  int returnsMeanLength() const;
};


///////////////////////////////// implementation part ///////////////////////////////

nvRRLModelTraits::nvRRLModelTraits()
  : _numInputReturns(10),
  _batchTrainLength(-1),
  _onlineTrainLength(100),
  _returnsMeanLength(1000),
  _transactionCost(0.00001)
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
  _returnsMeanLength = rhs._returnsMeanLength;
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

nvRRLModelTraits *nvRRLModelTraits::transactionCost(double cost)
{
  _transactionCost = cost;
  return GetPointer(this);
}

double nvRRLModelTraits::transactionCost() const
{
  return _transactionCost;
}

nvRRLModelTraits* nvRRLModelTraits::returnsMeanLength(int len)
{
  _returnsMeanLength = len;
  return GetPointer(this);
}

int nvRRLModelTraits::returnsMeanLength() const
{
  return _returnsMeanLength;
}
