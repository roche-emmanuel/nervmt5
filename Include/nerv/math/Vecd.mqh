//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include <nerv/core.mqh>

class nvVecd
{
protected:
  double _data[];
  uint _len;

public:
  /** Vector constructor:
  \param len: length of the vector.
  \param val: default element value.
  */
  nvVecd(uint len, double val = 0.0)
  {
    CHECK(len > 0, "Invalid vector length.");
    CHECK(ArrayResize(_data, len) == len, "Invalid result for ArrayResize()");
    _len = len;
  };

  ~nvVecd(void)
  {
  };

  uint size() const
  {
    return _len;
  }

  double at(const uint index) const
  {
    CHECK(index<_len,"Out of range index: "+STR(index))
    return _data[index];
  }

  double operator[](const uint index) const
  {
    return (at(index));
  }
};