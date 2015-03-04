
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
  nvVecd params;

  double Ft_1;
  double A;
  double B;

protected:
  nvRRLModelTraits _traits;
  nvVecd _returnMoment1;
  nvVecd _returnMoment2;
  nvVecd _signals;
  nvVecd _dFts[];
  int _len;
  int _pos; 

public:
  nvRRLTrainContext_SR()
    : A(0.0), B(0.0), _pos(0), _len(0)
  {

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
    params.resize(nm);

    // +2 below is because we also want to store the initial value of the training context data.
    _len = _traits.batchTrainLength() - _traits.numInputReturns() + 2;
    //CHECK(_len>0,"Invalid array length.");
    _len = MathMax(_len, 1);

    _returnMoment1.resize(_len);
    _returnMoment2.resize(_len);
    _signals.resize(_len);

    CHECK(ArrayResize(_dFts, _len) == _len, "Invalid length for dFt list");
    for(int i=0;i<_len;++i)
    {
      _dFts[i].resize(nm);
    }
  }

  virtual void pushState()
  {
    if (_pos < _len) {
      _returnMoment1.set(_pos, A);
      _returnMoment2.set(_pos, B);
      _signals.set(_pos, Ft_1);
      _dFts[_pos] = dFt_1;
      _pos++;
    }
    else {
      // Need to push back on the vector:
      _returnMoment1.push_back(A);
      _returnMoment2.push_back(B);
      _signals.push_back(Ft_1);
      for(int i=1;i<_len;++i)
      {
        _dFts[i-1] = _dFts[i];
      }
      _dFts[_len-1] = dFt_1;
    }
  }

  virtual void loadState(int nrets)
  {
    int offset = nrets - _traits.numInputReturns();
    int index = _len - 1 - offset;

    // For now we force the index to zero to simulate the previous implementation:
    //index = 0;
    // index = index - _traits.numInputReturns() + 1;

    CHECK(index >= 1, "Invalid index: " << index);

    A = _returnMoment1[index-1];
    B = _returnMoment2[index-1];
    Ft_1 = _signals[index-1];
    dFt_1 = _dFts[index-1];

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

  virtual double getSharpeRatioEMA() const
  {
    double AA = _returnMoment1.back();
    double BB = _returnMoment2.back();
    if (BB - AA * AA != 0.0) {
      return AA / MathSqrt(BB - AA * AA);
    }
    return 0.0;
  }

};
