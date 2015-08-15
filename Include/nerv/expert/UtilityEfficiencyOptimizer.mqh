#include <nerv/core.mqh>
#include <nerv/utils.mqh>
#include <nerv/math/Optimizer.mqh>
#include <nerv/expert/Deal.mqh>

class nvUtilityEfficiencyOptimizer : public nvOptimizer
{
protected:
  nvDeal* _deals[];

public:
  nvUtilityEfficiencyOptimizer()
  {
    setStopConditions(1e-12,0.0,0.0,0);
  }

  void assignDeals(nvDeal* &list[])
  {
    int num = ArraySize( list );
    CHECK(num>0,"Received empty deal list.")

    ArrayResize( _deals, 0 );
    ArrayCopy( _deals, list );

    reset();
  }

  void computeGradient(double &x[], double &grad[])
  {
    // Ensure that we have only one element:
    int size = ArraySize( x );
    CHECK(size==1,"Invalid size of input: "<<size);

    double alpha = x[0];

    // We should not consider alpha if its value is negative:
    if(alpha < 0.0)
    {
      return;
    }

    int num = ArraySize( _deals );
    grad[0] = 0.0;
    for(int i=0;i<num;++i)
    {
      grad[0]-=_deals[i].getProfitDerivative(alpha);
    }
  }

  double computeCost(double &x[])
  {
    int size = ArraySize( x );
    CHECK_RET(size==1,0.0,"Invalid size of input: "<<size);

    double alpha = x[0];

    // We should not consider alpha if its value is negative:
    if(alpha < 0.0)
    {
      return 1e+300;
    }

    int num = ArraySize( _deals );
    double val = 0;
    for(int i=0;i<num;++i)
    {
      val -= _deals[i].getProfitValue(alpha);
    }

    return val;
  }
};
