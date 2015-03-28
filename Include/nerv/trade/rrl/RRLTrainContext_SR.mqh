
#include <nerv/trades.mqh>
#include "RRLModelTraits.mqh"

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

protected:
  nvRRLModelTraits _traits;

#ifndef USE_OPTIMIZATIONS
  nvVecd _returnMoment1;
  nvVecd _returnMoment2;
  nvVecd _signals;
#else
  double _returnMoment1[];
  double _returnMoment2[];
  double _signals[];
#endif

  // nvVecd _dFts[];
  int _len;
  int _pos;

public:
  nvRRLTrainContext_SR()
    : _pos(0), _len(0)
  {

  }

  nvRRLTrainContext_SR(const nvRRLModelTraits &traits)
    : _pos(0), _len(0)
  {
    init(traits);
  }

  virtual void init(const nvRRLModelTraits &traits)
  {
    _traits = traits;

    int nm = traits.numInputReturns() + 2;
    A = 0.0;
    B = 0.0;
    Ft_1 = 0.0;
    dFt_1.resize(nm);
    dDt.resize(nm);

    // +2 below is because we also want to store the initial value of the training context data.
    _len = _traits.batchTrainLength() - _traits.numInputReturns() + 2;
    //CHECK(_len>0,"Invalid array length.");
    _len = MathMax(_len, 2);

#ifndef USE_OPTIMIZATIONS
    _returnMoment1.resize(_len);
    _returnMoment2.resize(_len);
    _signals.resize(_len);
#else
    CHECK(ArrayResize(_returnMoment1, _len) == _len, "Invalid length for _returnMoment1");
    CHECK(ArrayResize(_returnMoment2, _len) == _len, "Invalid length for _returnMoment2");
    CHECK(ArrayResize(_signals, _len) == _len, "Invalid length for _signals");
#endif

    // CHECK(ArrayResize(_dFts, _len) == _len, "Invalid length for dFt list");
    // for(int i=0;i<_len;++i)
    // {
    //   _dFts[i].resize(nm);
    // }
  }

  virtual void pushState()
  {
#ifndef USE_OPTIMIZATIONS
    if (_pos < _len) {
      _returnMoment1.set(_pos, A);
      _returnMoment2.set(_pos, B);
      _signals.set(_pos, Ft_1);
      // _dFts[_pos] = dFt_1;
      _pos++;
    }
    else {
      // Need to push back on the vector:
      _returnMoment1.push_back(A);
      _returnMoment2.push_back(B);
      _signals.push_back(Ft_1);
      // for(int i=1;i<_len;++i)
      // {
      //   _dFts[i-1] = _dFts[i];
      // }
      // _dFts[_len-1] = dFt_1;
    }
#else
    if (_pos < _len) {
      _returnMoment1[_pos] = A;
      _returnMoment2[_pos] = B;
      _signals[_pos] = Ft_1;
      // _dFts[_pos] = dFt_1;
      _pos++;
    }
    else {
      // Need to push back on the vector:
      nv_push_back(_returnMoment1, A);
      nv_push_back(_returnMoment2, B);
      nv_push_back(_signals, Ft_1);
      // for(int i=1;i<_len;++i)
      // {
      //   _dFts[i-1] = _dFts[i];
      // }
      // _dFts[_len-1] = dFt_1;
    }
#endif
  }

  virtual void loadStateIndex(int index)
  {
    CHECK(index >= 1, "Invalid index: " << index);

    A = _returnMoment1[index - 1];
    B = _returnMoment2[index - 1];
    Ft_1 = _signals[index - 1];
    // dFt_1 = _dFts[index-1];
    dFt_1.fill(0.0);

    // We write to the next position:
    _pos = index;

    // logDEBUG("Initial DFt_1 norm: "<< _context.dFt_1.norm());

    //_context.Ft_1 = getCurrentSignal();
    // _context.reset();
    // _context.Ft_1 = 0.0;
    // _context.dFt_1.fill(0.0);
    // double A = _context.A;
    // double B = _context.B;
    // if(B-A*A!=0.0) {
    //   logDEBUG("Initial SR: "<<(A/sqrt(B-A*A)));
    // }
  }

  virtual void loadState(int nrets)
  {
    int offset = nrets - _traits.numInputReturns();
    int index = _len - 1 - offset;

    // For now we force the index to zero to simulate the previous implementation:
    //index = 0;
    // index = index - _traits.numInputReturns() + 1;
    loadStateIndex(index);
  }

  virtual void addReturn(double Rt)
  {
    double adapt = 0.01;
    A = A + adapt * (Rt - A);
    B = B + adapt * (Rt * Rt - B);
  }

  virtual double getSR() const
  {
    if (B - A * A != 0.0) {
      return A / MathSqrt(B - A * A);
    }
    return 0.0;
  }

  virtual double computeMultiplier(double learningRate, double Rt) const
  {
    double sqB = sqrt(B);
    double denom = MathPow((sqB - A) * (sqB + A), 1.5);

    if (denom != 0.0)
    {
      return ((B - A * Rt) / denom) * learningRate;
    }

    return 0.0;
  }

};
