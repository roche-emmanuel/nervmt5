
#include <nerv/trades.mqh>
#include "RRLTrainContext_SR.mqh"

/*
Base class representing the data that can be passed to the RRL model class.
*/
class nvRRLTrainContext_DDR : public nvRRLTrainContext_SR
{
public:
  double DD2;

protected:
  nvVecd _downsideDeviation;

public:
  nvRRLTrainContext_DDR()
    : DD2(0.0),
    nvRRLTrainContext_SR()
  {

  }

  virtual void init(const nvRRLModelTraits &traits)
  {
    nvRRLTrainContext_SR::init(traits);
     
    int nm = traits.numInputReturns() + 2;
    DD2 = 0.0;
    int blen = _traits.batchTrainLength();

    _downsideDeviation.resize(MathMax(blen, 1));
  }

  virtual void pushState(double Ft, double Rt)
  {
    nvRRLTrainContext_SR::pushState(Ft,Rt);

    // now we can compute the new exponential moving averages:
    DD2 = _downsideDeviation.back();
    double eta = 0.01; // TODO: provide as traits.
    double val = MathMin(Rt,0.0);

    DD2 += eta * (val * val - DD2);

    _downsideDeviation.push_back(DD2);
  }

  virtual void loadStateIndex(int index)
  {

    nvRRLTrainContext_SR::loadStateIndex(index);

    CHECK(index >= 1, "Invalid index: " << index);
    DD2 = _downsideDeviation[index-1];
  }
};
