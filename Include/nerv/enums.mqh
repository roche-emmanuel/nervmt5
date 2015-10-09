#include <nerv/core.mqh>

enum MessageType
{
  MSGTYPE_UNKNOWN 								= 0,
  MSGTYPE_BALANCE_UPDATED					= 1,
  MSGTYPE_PORTFOLIO_STARTED 			= 2,
  MSGTYPE_TRADER_WEIGHT_UPDATED 	= 3,
};

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
