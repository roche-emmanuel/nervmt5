#include <nerv/core.mqh>

/*
Class: nvVirtualMarket

Class used to represent a virtual market evolving in parallel to the real market
but where the currency traders can perform trades with virtual money (and no real effect!)
*/
class nvVirtualMarket : public nvObject
{
public:
  /*
    Class constructor.
  */
  nvVirtualMarket()
  {
    // No op.
  }

  /*
    Copy constructor
  */
  nvVirtualMarket(const nvVirtualMarket& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvVirtualMarket& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvVirtualMarket()
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
