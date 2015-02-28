
#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include "BaseTraits.mqh"

/*
Base class representing the data that can be passed to the RRL model class.
*/
class nvTradeModelTraits : public nvBaseTraits
{
protected:
  double _epsg;
  double _epsf;
  double _epsx;
  int _maxIterations;

public:
  /* Default constructor,
  assign default values.*/
  nvTradeModelTraits();

  /* Copy constructor, will copy the values from the original */
  nvTradeModelTraits(const nvTradeModelTraits &rhs);

  /* Assignment operator. */
  nvTradeModelTraits *operator=(const nvTradeModelTraits &rhs);

  /* Assign epsilon value on gradient for training stop condition. */
  nvTradeModelTraits *epsilonG(double eps);

  /* Retrieve epsilong value for gradient. */
  double epsilonG() const;

  /* Assign epsilon value on function value for training stop condition. */
  nvTradeModelTraits *epsilonF(double eps);

  /* Retrieve epsilong value for function value. */
  double epsilonF() const;

  /* Assign epsilon value on parameters for training stop condition. */
  nvTradeModelTraits *epsilonX(double eps);

  /* Retrieve epsilong value for parameters. */
  double epsilonX() const;

  /* Assign the maximum number of iterations to perform during training. */
  nvTradeModelTraits *maxIterations(int num);

  /* Retrieve the maximum number of iterations. */
  int maxIterations() const;
};


///////////////////////////////// implementation part ///////////////////////////////

nvTradeModelTraits::nvTradeModelTraits()
  : _epsg(0.0000000001),
    _epsf(0.0),
    _epsx(0.0),
    _maxIterations(100),
    nvBaseTraits()
{
}

nvTradeModelTraits::nvTradeModelTraits(const nvTradeModelTraits &rhs)
{
  this = rhs;
}

nvTradeModelTraits *nvTradeModelTraits::operator=(const nvTradeModelTraits &rhs)
{
  nvBaseTraits::operator=(rhs);
  _epsg = rhs._epsg;
  _epsf = rhs._epsf;
  _epsx = rhs._epsx;
  _maxIterations = rhs._maxIterations;
  return THIS;
}

nvTradeModelTraits *nvTradeModelTraits::epsilonG(double eps)
{
  _epsg = eps;
  return THIS;
}

double nvTradeModelTraits::epsilonG() const
{
  return _epsg;
}

nvTradeModelTraits *nvTradeModelTraits::epsilonF(double eps)
{
  _epsf = eps;
  return THIS;
}

double nvTradeModelTraits::epsilonF() const
{
  return _epsf;
}

nvTradeModelTraits *nvTradeModelTraits::epsilonX(double eps)
{
  _epsx = eps;
  return THIS;
}

double nvTradeModelTraits::epsilonX() const
{
  return _epsx;
}

nvTradeModelTraits *nvTradeModelTraits::maxIterations(int num)
{
  _maxIterations = num;
  return THIS;
}

int nvTradeModelTraits::maxIterations() const
{
  return _maxIterations;
}
