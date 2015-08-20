#include <nerv/core.mqh>

/*
Class: nvBootstrapper

Base class used to compute bootstrap statistics.
*/
class nvBootstrapper : public nvObject
{
protected:
  // Size of the observed sample:
  int _size;

  // Number of bootstrap evaluations that should be conducted:
  int _B;

  // Vectors of bootstrapped computations:
  double _bootValues[];

  // Boot estimate of the computed statistic:
  double _bootEstimate;

  // Boot standard error on the compute statistic:
  double _bootStandardError;

  // Falg to indicated if the boot samples are already sorted or not:
  bool _sorted;

public:
  /*
    Class constructor.
  */
  nvBootstrapper()
  {
    _size = 0;
    _B = 0;
    _sorted = false;
    _bootEstimate = 0.0;
    _bootStandardError = 0.0;
  }

  /*
    Copy constructor
  */
  nvBootstrapper(const nvBootstrapper& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvBootstrapper& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvBootstrapper()
  {
    // No op.
  }

  /*
  Function: compute
  
  Method used to compute the desired statistic on a specific shuttled sample array.
  This method should be overrided by derived class.
  */
  virtual double compute(double &x[])
  {
    // no implementation by default:
    THROW("No implementation");
    return 0.0;
  }
  
  /*
  Function: evaluate
  
  Main method called to evaluate the bootstrap on the provided sample observations.
  */
  double evaluate(double &x[], int Bsize = 999, SimpleRNG* rng = NULL)
  {
    _sorted = false;
    _B = Bsize;
    _size = ArraySize( x );
    CHECK_RET(_size>2,0.0,"Not enough elements in bootstrap evaluation.");

    ArrayResize( _bootValues, _B );

    double shuttled[];
    ArrayResize( shuttled, _size );

    // use the portfolioManager for shuttling:
    SimpleRNG defrng;
    defrng.SetSeedFromSystemTime();
    
    if(rng==NULL)
    {
      rng = GetPointer(defrng);
    }

    // perform evaluation for each bootstrap sample:
    for(int i=0;i<_B;++i)
    {
      // Generate the shuttled sample:
      for(int j=0;j<_size;++j)
      {
        shuttled[j] = x[rng.GetInt(0,_size-1)];
      }

      // Compute the statistic on that shuttled vector and store the result:
      _bootValues[i] = compute(shuttled);
    }

    // Compute the boot estimation and standard error:
    _bootEstimate = nvGetMeanEstimate(_bootValues);
    _bootStandardError = nvGetStdDevEstimate(_bootValues,_bootEstimate);

    return _bootEstimate;
  }
  
  /*
  Function: getBootEstimate
  
  Retrieve the estimated bootstrap value for the computed statistic.
  */
  double getBootEstimate()
  {
    return _bootEstimate;
  }
  
  /*
  Function: getStandardError
  
  Retrieve the standard error on the estimate of the computed statistic
  as computed by the bootstrap algorithm.
  */
  double getStandardError()
  {
    return _bootStandardError;
  }
  
  /*
  Function: getBootSamples
  
  Retrieve the values of the samples computed by the bootstrap algorithm
  */
  void getBootSamples(double &values[])
  {
    int num = ArraySize( _bootValues );
    ArrayResize( values, num );
    ArrayCopy( values, _bootValues);
  }
  
  /*
  Function: sortBootSamples
  
  Method called to sort the bootstrap samples (if not done yet)
  */
  void sortBootSamples()
  {
    if(_sorted)
      return; // nothing to do.

    ArraySort( _bootValues );
    _sorted = true;
  }
  
  /*
  Function: getMaxValue
  
  Retrieve the max value of the confidence interval with a given 
  confidence level, using the quantile evaluation.
  */
  double getMaxValue(double confidence)
  {
    CHECK_RET(0<=confidence && confidence<=1.0,0.0,"Invalid confidence value: "<<confidence);

    // The confidence level is centered on the mean value, so we need to add a "little something"
    double level = confidence + (1.0 - confidence)*0.5;

    int index = (int)MathFloor(_B*level + 0.5);

    sortBootSamples();
    return _bootValues[index];
  }
  
  /*
  Function: getMinValue
  
  Retrieve the min value of the confidence interval with a given 
  confidence level, using the quantile evaluation.  
  */
  double getMinValue(double confidence)
  {
    CHECK_RET(0<=confidence && confidence<=1.0,0.0,"Invalid confidence value: "<<confidence);

    // The confidence level is centered on the mean value, so we need to only take into account
    // what is "left" on the left side:
    double level = (1.0 - confidence)*0.5;

    int index = (int)MathFloor(_B*level + 0.5);

    sortBootSamples();
    return _bootValues[index];    
  }
  
};


// Standard Mean bootstrapper
class nvMeanBootstrap : public nvBootstrapper
{
public:
  // In the compute method, we receive the shuttled version of the observed sample
  virtual double compute(double &x[])
  {
    // Compute the mean of the boot sample:
    return nvGetMeanEstimate(x);
  }
};

// Standard deviation bootstrapper:
class nvStdDevBootstrap : public nvBootstrapper
{
public:
  // In the compute method, we receive the shuttled version of the observed sample
  virtual double compute(double &x[])
  {
    return nvGetStdDevEstimate(x);
  }
};
