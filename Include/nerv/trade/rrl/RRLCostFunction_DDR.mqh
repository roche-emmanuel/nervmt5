
#include <nerv/core.mqh>
#include <nerv/trades.mqh>
#include <nerv/trade/rrl/RRLModelTraits.mqh>
#include <nerv/trade/rrl/RRLCostFunction.mqh>
#include <nerv/trade/rrl/RRLTrainContext_DDR.mqh>

class nvRRLCostFunction_DDR : public nvRRLCostFunction
{
public:
  nvRRLCostFunction_DDR(const nvRRLModelTraits &traits);

  virtual void computeCost();

protected:
  virtual double getCurrentCost() const;
};


//////////////////////////////////// implementation part ///////////////////////////
nvRRLCostFunction_DDR::nvRRLCostFunction_DDR(const nvRRLModelTraits &traits)
  : nvRRLCostFunction(traits)
{
  _ctx = new nvRRLTrainContext_DDR(traits);
}

void nvRRLCostFunction_DDR::computeCost()
{
  NO_IMPL();
}

double nvRRLCostFunction_DDR::getCurrentCost() const
{
  return -_ctx.getDDR();
}

