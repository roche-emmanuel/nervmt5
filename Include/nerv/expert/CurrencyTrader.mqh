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

  /*
  Utility value for this currency trader: determine how efficiency this
  trader is in generating profits instead of losses.
  Default value will be 0.0, indicating no bias towards profits or losses.
  Then positive values should indicates that this currency trader is generating
  profits whereas negative values would indicate losses.
  */
  double _utility;
public:
  /*
    Class constructor.
  */
  nvCurrencyTrader(string symbol)
  {
    // Store the symbol assigned to this trader:
    _symbol = symbol;

    // Set default utility value:
    _utility = 0.0;
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
  Function: getWeight
  
  Retrieve the weight currently assigned to this trader
  */
  double getWeight()
  {
    return _weight;
  }
  
  /*
  Function: getUtility
  
  Retrieve the current utility value of this trader
  */
  double getUtility()
  {
    return _utility;
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
