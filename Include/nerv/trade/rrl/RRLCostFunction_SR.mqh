
#include <nerv/core.mqh>
#include <nerv/trades.mqh>
#include <nerv/trade/rrl/RRLModelTraits.mqh>
#include <nerv/trade/rrl/RRLCostFunction.mqh>
#include <nerv/trade/rrl/RRLTrainContext_SR.mqh>

class nvRRLCostFunction_SR : public nvRRLCostFunction
{
public:
  nvRRLCostFunction_SR(const nvRRLModelTraits &traits);

protected:
  virtual double getCurrentCost() const;
};


//////////////////////////////////// implementation part ///////////////////////////
nvRRLCostFunction_SR::nvRRLCostFunction_SR(const nvRRLModelTraits &traits)
  : nvRRLCostFunction(traits)
{
  _ctx = new nvRRLTrainContext_SR(traits);
}

double nvRRLCostFunction_SR::getCurrentCost() const
{
  return -_ctx.getSR();
}
