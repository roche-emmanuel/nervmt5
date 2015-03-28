#include <nerv/trades.mqh>

/* Base class used to represent a training context */
class nvTrainContext : public nvObject
{
public:
  double Ft_1;
  double A;
  double B;

public:
  nvTrainContext() : A(0.0), B(0.0), Ft_1(0.0)
  {

  }

  virtual void pushState()
  {
    NO_IMPL();
  }

  virtual void loadState(int nrets)
  {
    NO_IMPL();
  }

  virtual double getSR() const
  {
    NO_IMPL();
    return 0.0;
  }

  virtual double getDDR() const
  {
    NO_IMPL();
    return 0.0;
  }

  virtual void addReturn(double Rt)
  {
    NO_IMPL();
  }

  virtual double computeMultiplier(double learningRate, double Rt) const
  {
    NO_IMPL();
    return 0.0;
  }
};  
