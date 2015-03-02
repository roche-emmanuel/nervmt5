
#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include "BaseTraits.mqh"

enum TrainingMode
{
  TRAIN_BATCH_CONJUGATE_GRADIENT,
  TRAIN_BATCH_GRADIENT_DESCENT,
  TRAIN_STOCHASTIC_GRADIENT_DESCENT
};

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
  double _lambda;

  bool _returnsMeanDevFixed;
  double _returnsMean;
  double _returnsDev;

  double _learningRate;
  int _numEpochs;

  TrainingMode _trainMode;

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

  /* Set regularization parameter. */
  nvTradeModelTraits* lambda(double reg);

  /* Retrieve the regularization parameter. */
  double lambda() const;  

  /* Used to fix the return mean and deviation values for this model. */
  nvTradeModelTraits* fixReturnsMeanDev(double mean, double dev);

  /* Check if this the return mean/dev are fixed. */
  bool returnsMeanDevFixed() const;

  /* retrieve the fixed return mean. */
  double returnsMean() const;

  /* retrieve the fixed returns dev. */
  double returnsDev() const;

  /* Specify the learning rate to use in case of simple gradient descent.*/
  nvTradeModelTraits* learningRate(double lr);

  /* Retrieve le learning rate value.*/
  double learningRate() const;

  /* Specify the number or epochs to use when training with simple gradient descent. */
  nvTradeModelTraits* numEpochs(int num);

  /* Retrieve the number of epochs. */
  int numEpochs() const;

  /* Specify the training mode to use. */
  nvTradeModelTraits* trainMode(TrainingMode mode);

  /* Retrieve the training mode to use. */
  TrainingMode trainMode() const;
};


///////////////////////////////// implementation part ///////////////////////////////

nvTradeModelTraits::nvTradeModelTraits()
  : _epsg(0.0000000001),
    _epsf(0.0),
    _epsx(0.0),
    _maxIterations(100),
    _lambda(0.0),
    _returnsMeanDevFixed(false),
    _returnsMean(0.0),
    _returnsDev(0.0),
    _learningRate(0.01),
    _numEpochs(20),
    _trainMode(TRAIN_BATCH_CONJUGATE_GRADIENT),
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
  _lambda = rhs._lambda;
  _returnsMeanDevFixed = rhs._returnsMeanDevFixed;
  _returnsMean = rhs._returnsMean;
  _returnsDev = rhs._returnsDev;
  _learningRate = rhs._learningRate;
  _numEpochs = rhs._numEpochs;
  _trainMode = rhs._trainMode;
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

nvTradeModelTraits* nvTradeModelTraits::lambda(double reg)
{
  _lambda = reg;
  return THIS;
}

double nvTradeModelTraits::lambda() const
{
  return _lambda;
}

nvTradeModelTraits* nvTradeModelTraits::fixReturnsMeanDev(double mean, double dev)
{
  _returnsMeanDevFixed = true;
  _returnsMean = mean;
  _returnsDev = dev;
  return THIS;
}

bool nvTradeModelTraits::returnsMeanDevFixed() const
{
  return _returnsMeanDevFixed;
}

double nvTradeModelTraits::returnsMean() const
{
  return _returnsMean;
}

double nvTradeModelTraits::returnsDev() const
{
  return _returnsDev;
}

nvTradeModelTraits* nvTradeModelTraits::learningRate(double lr)
{
  _learningRate = lr;
  return THIS;
}

double nvTradeModelTraits::learningRate() const
{
  return _learningRate;
}

nvTradeModelTraits* nvTradeModelTraits::numEpochs(int num)
{
  _numEpochs = num;
  return THIS;
}

int nvTradeModelTraits::numEpochs() const
{
  return _numEpochs;
}

nvTradeModelTraits* nvTradeModelTraits::trainMode(TrainingMode mode)
{
  _trainMode = mode;
  return THIS;
}

TrainingMode nvTradeModelTraits::trainMode() const
{
  return _trainMode;
}
