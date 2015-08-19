#include <nerv/core.mqh>
#include <nerv/expert/Market.mqh>

/*
Class: nvVirtualMarket

Class used to represent a virtual market evolving in parallel to the real market
but where the currency traders can perform trades with virtual money (and no real effect!)
*/
class nvVirtualMarket : public nvMarket
{
public:
  /*
    Class constructor.
  */
  nvVirtualMarket()
  {
    _marketType = MARKET_TYPE_VIRTUAL;
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
};
