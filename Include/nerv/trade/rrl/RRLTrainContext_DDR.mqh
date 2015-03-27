
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
#ifndef USE_OPTIMIZATIONS
  nvVecd _downsideDeviation;
#else
  double _downsideDeviation[];
#endif

public:
  nvRRLTrainContext_DDR()
    : DD2(0.0),
    nvRRLTrainContext_SR()
  {

  }

  virtual void init(const nvRRLModelTraits &traits)
  {
    nvRRLTrainContext_SR::init(traits);
     
    DD2 = 0.0;
#ifndef USE_OPTIMIZATIONS
    _downsideDeviation.resize(_len);
#else
    CHECK(ArrayResize(_downsideDeviation, _len) == _len, "Invalid length for _signals");
#endif

  }

  virtual void pushState()
  {
#ifndef USE_OPTIMIZATIONS
    if (_pos < _len) {
      _downsideDeviation.set(_pos, DD2);      
      // Note that we don't update the position here,
      // This will be taken care of by the parent implementation.
      //_pos++;
    }
    else {
      // Need to push back on the vector:
      _downsideDeviation.push_back(DD2);
    }
#else
    if (_pos < _len) {
      _downsideDeviation[_pos] = DD2;      
      // Note that we don't update the position here,
      // This will be taken care of by the parent implementation.
      //_pos++;
    }
    else {
      // Need to push back on the vector:
      nv_push_back(_downsideDeviation,DD2);
    }
#endif


    // We call the parent implementation **after**
    // doing our changes, since it might change the target position _pos.
    nvRRLTrainContext_SR::pushState();
  }

  virtual void loadStateIndex(int index)
  {
    nvRRLTrainContext_SR::loadStateIndex(index);

    CHECK(index >= 1, "Invalid index: " << index);
    DD2 = _downsideDeviation[index-1];
  }

  virtual void addReturn(double Rt)
  {
    nvRRLTrainContext_SR::addReturn(Rt);    
      
    double adapt = 0.01;
    double val = MathMin(Rt,0);
    DD2 = DD2 + adapt * (val * val - DD2);
  }

  virtual double getDDR() const
  {
    if(DD2!=0.0) {
      return A/MathSqrt(DD2);
    }
    return 0.0;
  }
};
