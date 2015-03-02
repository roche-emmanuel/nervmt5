
#include <nerv/trades.mqh>

/*
Base class representing the data that can be passed to the RRL model class.
*/
class nvRRLTrainContext_SR : public nvTrainContext
{
public:
  nvVecd dFt_1;
  nvVecd dFt;
  nvVecd dRt;
  nvVecd dDt;
  nvVecd params;

  double Ft_1;
  double A;
  double B;

public:
  nvRRLTrainContext_SR()
    : A(0.0), B(0.0)
  {

  }

  void init(const nvRRLModelTraits &traits)
  {
    int nm = traits.numInputReturns()+2;
    A = 0.0;
    B = 0.0;
    Ft_1 = 0.0;
    dFt_1.resize(nm);
    dDt.resize(nm);
    params.resize(nm);
  }

  void reset()
  {
    Ft_1 = 0.0;
    dFt_1.fill(0.0);
  }

};
