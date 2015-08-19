#include <nerv/core.mqh>
#include <nerv/expert/Market.mqh>

/*
Class: nvRealMarket

Class used to represent the real market, where the currency traders can perform actual (real) trades
with real money... Use carefully :-).
*/
class nvRealMarket : public nvMarket
{
public:
  /*
    Class constructor.
  */
  nvRealMarket()
  {
    _marketType = MARKET_TYPE_REAL;
  }

  /*
    Copy constructor
  */
  nvRealMarket(const nvRealMarket& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvRealMarket& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvRealMarket()
  {
    // No op.
  }

  /*
  Function: hasOpenPosition
  
  Method used to check if we currently have an open position for a given symbol:
  */
  bool hasOpenPosition(string symbol)
  {
    // TODO: provide implementation.
    return false;
  }
  
};
