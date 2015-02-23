
#include <nerv/core.mqh>
#include <nerv/math.mqh>

/*
Base class representing the data that can be passed to the cost function computation
algorithm.
*/
class nvRRLTrainTraits : public nvObject
{
protected:
  nvVecd _returns;
  double _transactionCost;
  int _initialSignal;
  int _finalSignal;
  double _epsg;
  double _epsf;
  double _epsx;
  int _maxIterations;

public:
  /* Default constructor,
  assign default values.*/
  nvRRLTrainTraits();

  /* Copy constructor, will copy the values from the original */
  nvRRLTrainTraits(const nvRRLTrainTraits &rhs);

  /* Assignment operator. */
  nvRRLTrainTraits *operator=(const nvRRLTrainTraits &rhs);

  /* Assign the returns vector. */
  nvRRLTrainTraits *returns(const nvVecd &returns);

  /* Retrieve the return vector. */
  nvVecd *returns() const;

  /* Assign the transaction cost. */
  nvRRLTrainTraits *transactionCost(double cost);

  /* Retrieve the transaction cost. */
  double transactionCost() const;

  /* Flag used to decide if we should use the initial signal during training.
  This method will simply check if the current initialSignal value is valid. */
  bool useInitialSignal() const;

  /* Flag used to decide if we should use the final signal during training.
  This method will simply check if the current finalSignal value is valid. */
  bool useFinalSignal() const;

  /* Assign the initial signal value. */
  nvRRLTrainTraits *initialSignal(int sig);

  /* Retrieve the initial signal value. */
  int initialSignal() const;

  /* Assign the final signal value. */
  nvRRLTrainTraits *finalSignal(int sig);

  /* Retrieve the final signal value. */
  int finalSignal() const;

  /* Assign epsilon value on gradient for training stop condition. */
  nvRRLTrainTraits *epsilonG(double eps);

  /* Retrieve epsilong value for gradient. */
  double epsilonG() const;

  /* Assign epsilon value on function value for training stop condition. */
  nvRRLTrainTraits *epsilonF(double eps);

  /* Retrieve epsilong value for function value. */
  double epsilonF() const;

  /* Assign epsilon value on parameters for training stop condition. */
  nvRRLTrainTraits *epsilonX(double eps);

  /* Retrieve epsilong value for parameters. */
  double epsilonX() const;

  /* Assign the maximum number of iterations to perform during training. */
  nvRRLTrainTraits *maxIterations(int num);

  /* Retrieve the maximum number of iterations. */
  int maxIterations() const;

};


///////////////////////////////// implementation part ///////////////////////////////

nvRRLTrainTraits::nvRRLTrainTraits()
  : _transactionCost(0.00001),
    _initialSignal(-2),
    _finalSignal(-2),
    _epsg(0.0000000001),
    _epsf(0.0),
    _epsx(0.0)
{
}

nvRRLTrainTraits::nvRRLTrainTraits(const nvRRLTrainTraits &rhs)
{
  this = rhs;
}

nvRRLTrainTraits *nvRRLTrainTraits::operator=(const nvRRLTrainTraits &rhs)
{
  _returns = rhs._returns;
  _transactionCost = rhs._transactionCost;
  _initialSignal = rhs._initialSignal;
  _finalSignal = rhs._finalSignal;
  _epsg = rhs._epsg;
  _epsf = rhs._epsf;
  _epsx = rhs._epsx;
  return GetPointer(this);
}

nvRRLTrainTraits *nvRRLTrainTraits::returns(const nvVecd &returns)
{
  _returns = returns;
  return GetPointer(this);
}

nvVecd *nvRRLTrainTraits::returns() const
{
  return GetPointer(_returns);
}

nvRRLTrainTraits *nvRRLTrainTraits::transactionCost(double cost)
{
  _transactionCost = cost;
  return GetPointer(this);
}

double nvRRLTrainTraits::transactionCost() const
{
  return _transactionCost;
}

bool nvRRLTrainTraits::useInitialSignal() const
{
  return (_initialSignal >= -1 && _initialSignal <= 1);
}

bool nvRRLTrainTraits::useFinalSignal() const
{
  return (_finalSignal >= -1 && _finalSignal <= 1);
}

nvRRLTrainTraits *nvRRLTrainTraits::initialSignal(int sig)
{
  _initialSignal = sig;
  return GetPointer(this);
}

/* Retrieve the initial signal value. */
int nvRRLTrainTraits::initialSignal() const
{
  return _initialSignal;
}

/* Assign the final signal value. */
nvRRLTrainTraits *nvRRLTrainTraits::finalSignal(int sig)
{
  _finalSignal = sig;
  return GetPointer(this);
}

/* Retrieve the final signal value. */
int nvRRLTrainTraits::finalSignal() const
{
  return _finalSignal;
}

nvRRLTrainTraits *nvRRLTrainTraits::epsilonG(double eps)
{
  _epsg = eps;
  return GetPointer(this);
}

double nvRRLTrainTraits::epsilonG() const
{
  return _epsg;
}

nvRRLTrainTraits *nvRRLTrainTraits::epsilonF(double eps)
{
  _epsf = eps;
  return GetPointer(this);
}

double nvRRLTrainTraits::epsilonF() const
{
  return _epsf;
}

nvRRLTrainTraits *nvRRLTrainTraits::epsilonX(double eps)
{
  _epsx = eps;
  return GetPointer(this);
}

double nvRRLTrainTraits::epsilonX() const
{
  return _epsx;
}

nvRRLTrainTraits *nvRRLTrainTraits::maxIterations(int num)
{
  _maxIterations = num;
  return GetPointer(this);
}

int nvRRLTrainTraits::maxIterations() const
{
  return _maxIterations;
}
