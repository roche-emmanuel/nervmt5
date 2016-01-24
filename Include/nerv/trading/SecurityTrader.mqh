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
    
    _riskLevel = 0.03;
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

  bool closePosition()
  {
    return nvClosePosition(_symbol);
  }

  bool hasPosition()
  {
    return PositionSelect(_symbol);
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
