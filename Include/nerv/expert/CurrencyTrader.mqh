#include <nerv/core.mqh>

#include <nerv/expert/PortfolioManager.mqh>

/*
Class: nvCurrencyTrader

This class represents a trader that will operate on a fixed currency.
*/
class nvCurrencyTrader : public nvObject
{
protected:
  string _symbol;
  
  // The weight that should be assigned to this trader
  // when performing the "lot sizing" operation for a deal
  // compared to the other traders. The value should be in the 
  // range [0,1]
  double _weight;

public:
  /*
    Class constructor.
  */
  nvCurrencyTrader(string symbol)
  {
    // Store the symbol assigned to this trader:
    _symbol = symbol;
  }

  /*
    Copy constructor
  */
  nvCurrencyTrader(const nvCurrencyTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    assignment operator
  */
  void operator=(const nvCurrencyTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvCurrencyTrader()
  {
    // No op.
  }

  /*
  Function: getSymbol
  
  Retrieve the symbol corresponding to this trader.
  THe symbol is used as a unique name for the trader.
  */
  string getSymbol()
  {
    return _symbol;
  }
  
  /*
  Function: setWeight
  
  Set the weight value of this trader
  */
  void setWeight(double val)
  {
    CHECK(val>=0.0 && val<=1.0,"Invalid weight value: "<<val)
    _weight = val;
  }
  
  /*
  Function: update
  
  Method called to update the complete state of this Portfolio Manager
  */
  void update()
  {
    logDEBUG(TimeLocal()<<": Updating CurrencyTrader.")
  }
  
};
