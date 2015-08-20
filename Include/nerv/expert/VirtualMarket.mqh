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

  /*
  Function: doOpenPosition
  
  Method called to actually open a position on a given symbol on that market.
  Note that the stoploss value is given in number of points.
  */
  virtual bool doOpenPosition(nvDeal* deal)
  {
    // do nothing special.    
    return true;
  }

  /*
  Function: doClosePosition
  
  Method called to actually close a position on a given symbol on that market.
  Must be reimplemented by derived classes.
  */
  virtual void doClosePosition(nvDeal* deal)
  {
    // No op.
  }  
};
