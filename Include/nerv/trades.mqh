
#include <nerv/core.mqh>
#include <nerv/math.mqh>
#include <nerv/trade/RRLModel.mqh>

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
