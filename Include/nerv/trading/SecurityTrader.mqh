#include <nerv/core.mqh>
#include <nerv/core/Object.mqh>

/*
Class: nvSecurityTrader

Base class representing a trader 
*/
class nvSecurityTrader : public nvObject
{
protected:
  string _symbol;
  double _psize;

  double _riskLevel;
  double _traderWeight;

public:
  /*
    Class constructor.
  */
  nvSecurityTrader(string symbol)
  {
    logDEBUG("Creating Security Trader for "<<symbol)

    _symbol = symbol;
    _psize = nvGetPointSize(_symbol);
    
    _riskLevel = 0.02;
    _traderWeight = 1.0;
  }

  /*
    Copy constructor
  */
  nvSecurityTrader(const nvSecurityTrader& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvSecurityTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvSecurityTrader()
  {
    logDEBUG("Deleting SecurityTrader")
  }

  int openPosition(int otype, double lot, double sl = 0.0, 
    double tp = 0.0, double price = 0.0)
  {
    return nvOpenPosition(_symbol,otype,lot,sl,tp,price);
  }

  void setRiskLevel(double risk)
  {
    _riskLevel = risk;
  }

  bool closePosition()
  {
    return nvClosePosition(_symbol);
  }

  bool hasPosition()
  {
    return PositionSelect(_symbol);
  }
  
  bool isLong()
  {
    if(hasPosition())
    {
      return PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY;
    }
    return false;
  }

  bool isShort()
  {
    if(hasPosition())
    {
      return PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL;
    }
    return false;
  }

  /*
  Function: evaluateLotSize
  
  Main method of this class used to evaluate the lot size that should be used for a potential trade.
  */
  double evaluateLotSize(double numLostPoints, double confidence)
  {
    return nvEvaluateLotSize(_symbol, numLostPoints, _riskLevel, _traderWeight, confidence);
  }

  /*
  Function: update
  
  Method called to update the state of this trader 
  normally once every fixed time delay.
  */
  virtual void update(datetime ctime)
  {

  }
  
  virtual void onTick()
  {

  }


};
