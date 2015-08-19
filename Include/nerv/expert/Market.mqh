#include <nerv/core.mqh>

enum MarketType
{
  MARKET_TYPE_UNKNOWN,
  MARKET_TYPE_REAL,
  MARKET_TYPE_VIRTUAL,
};

enum PositionType
{
  POS_NONE,
  POS_LONG,
  POS_SHORT,
};

/*
Class: nvMarket

Base class used to represent a market on which currency trader can open/close positions
*/
class nvMarket : public nvObject
{
protected:
  // The type of this market
  MarketType _marketType;

public:
  /*
    Class constructor.
  */
  nvMarket()
  {
    _marketType = MARKET_TYPE_UNKNOWN;
  }

  /*
    Copy constructor
  */
  nvMarket(const nvMarket& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvMarket& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvMarket()
  {
    // No op.
  }

  /*
  Function: getMarketType
  
  Retrieve the type of this market
  */
  MarketType getMarketType()
  {
    return _marketType;
  }
  
  /*
  Function: openPosition
  
  Method called to open a position this market for a given symbol.
  Must be reimplemented by derived classes.
  */
  void openPosition(string symbol, ENUM_ORDER_TYPE otype, double lot, double sl = 0.0)
  {
    THROW("No implementation");
  }
  
  /*
  Function: closePosition
  
  Method called to close a position on a given symbol on that market.
  Must be reimplemented by derived classes.
  */
  virtual void closePosition(string symbol)
  {
    THROW("No implementation");
  }
  
  /*
  Function: getPositionType
  
  Retrieve the current position type on a symbol.
  Must be reimplemented by derived classes.
  */
  PositionType getPositionType(string symbol)
  {
    THROW("No implementation");
    return POS_NONE;
  }
  
  /*
  Function: hasOpenPosition
  
  Method used to check if there is currently an open position for a given symbol on this market.
  */
  bool hasOpenPosition(string symbol)
  {
    return getPositionType(symbol)!=POS_NONE;
  }
  
};
