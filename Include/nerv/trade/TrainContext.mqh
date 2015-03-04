#include <nerv/trades.mqh>

/* Base class used to represent a training context */
class nvTrainContext : public nvObject
{
public:
  virtual void pushState()
  {
    NO_IMPL();
  }

  virtual void loadState(int nrets)
  {
    NO_IMPL();
  }

  virtual double getSharpeRatioEMA() const
  {
    NO_IMPL();
    return 0.0;
  }
};  
