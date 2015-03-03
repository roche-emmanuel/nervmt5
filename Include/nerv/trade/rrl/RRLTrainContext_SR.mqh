
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

public:
  nvRRLTrainContext_SR()
    : A(0.0), B(0.0)
  {

  }

  void init(const nvRRLModelTraits &traits)
  {
    _traits = traits;

    int nm = traits.numInputReturns()+2;
    A = 0.0;
    B = 0.0;
    Ft_1 = 0.0;
    dFt_1.resize(nm);
    dDt.resize(nm);
    params.resize(nm);

    int blen = _traits.batchTrainLength();

    _returnMoment1.resize(MathMax(blen, 1));
    _returnMoment2.resize(MathMax(blen, 1));
    _signals.resize(MathMax(blen, 1));
  }

  virtual void pushState(double Ft, double Rt)
  {
    // now we can compute the new exponential moving averages:
    double AA = _returnMoment1.back();
    double BB = _returnMoment2.back();
    double eta = 0.01; // TODO: provide as traits.
    AA += eta * (Rt - AA);
    BB += eta * (Rt * Rt - BB);

    _returnMoment1.push_back(AA);
    _returnMoment2.push_back(BB);
    _signals.push_back(Ft);
  }

  void reset()
  {
    Ft_1 = 0.0;
    dFt_1.fill(0.0);
  }

  virtual void loadState(int offset)
  {
    int index = (int)_returnMoment1.size() - 1 - offset;
    
    CHECK(index>=0,"Invalid index: "<<index);

    // For now we force the index to zero to simulate the previous implementation:
    index = 0;

    A = _returnMoment1[index];
    B = _returnMoment2[index];
    Ft_1 = _signals[index];
    dFt_1.fill(0.0); // This is not completely correct.
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
