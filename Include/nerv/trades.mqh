
#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include <nerv/trade/rrl/RRLCostFunction.mqh>

nvVecd nv_get_return_prices(int count, string symbol = "EURUSD", ENUM_TIMEFRAMES period = PERIOD_M1, int offset = 0)
{
  double arr[];

  int res = CopyClose(symbol, period, 0+offset, count, arr);
  CHECK(res==count,"Invalid copyclose result: "<<res<<"!="<<count);

  nvVecd cur_prices(arr);

  //logDEBUG("Current price vector is: "<<cur_prices);

  res = CopyClose(symbol, period, 1+offset, count, arr);
  CHECK(res==count,"Invalid copyclose result: "<<res<<"!="<<count);

  nvVecd prev_prices(arr);

  return cur_prices - prev_prices;
}

/* Retrieve the bar duration in seconds depending on the selected period. */
ulong getBarDuration(ENUM_TIMEFRAMES period)
{
  switch (period)
  {
  case PERIOD_M1: return 60;
  case PERIOD_M2: return 60 * 2;
  case PERIOD_M3: return 60 * 3;
  case PERIOD_M4: return 60 * 4;
  case PERIOD_M5: return 60 * 5;
  case PERIOD_M6: return 60 * 6;
  case PERIOD_M10: return 60 * 10;
  case PERIOD_M12: return 60 * 12;
  case PERIOD_M15: return 60 * 15;
  case PERIOD_M20: return 60 * 20;
  case PERIOD_M30: return 60 * 30;
  case PERIOD_H1: return 3600;
  case PERIOD_H2: return 3600 * 2;
  case PERIOD_H3: return 3600 * 3;
  case PERIOD_H4: return 3600 * 4;
  case PERIOD_H6: return 3600 * 6;
  case PERIOD_H8: return 3600 * 8;
  case PERIOD_H12: return 3600 * 12;
  }
 
  THROW("Unsupported period value " << (int)period);
  return 0;
}
