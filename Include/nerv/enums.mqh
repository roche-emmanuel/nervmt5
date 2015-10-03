#include <nerv/core.mqh>

enum MessageType
{
  MSGTYPE_UNKNOWN,
  MSGTYPE_BALANCE_UPDATED,
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
