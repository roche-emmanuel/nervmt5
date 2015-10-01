//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

// Base class for all NervTech elements.
class nvStringStream : public nvObject
{
protected:
  string _buf;

public:
  nvStringStream()
  {
    _buf = "";
  };

  ~nvStringStream() {};

  string str() const
  {
    return _buf;
  }

  virtual string toString() const
  {
    return "[nvStringStream]";
  }

  nvStringStream *operator<<(string rhs)
  {
    _buf += rhs;
    return GetPointer(this);
  }

  nvStringStream *operator<<(const nvObject &rhs)
  {
    _buf += rhs.toString();
    return GetPointer(this);
  }

  nvStringStream *operator<<(short rhs)
  {
    _buf += (string)rhs;
    return GetPointer(this);
  }

  nvStringStream *operator<<(ushort rhs)
  {
    _buf += (string)rhs;
    return GetPointer(this);
  }

  nvStringStream *operator<<(uchar rhs)
  {
    _buf += (string)rhs;
    return GetPointer(this);
  }

  nvStringStream *operator<<(int rhs)
  {
    _buf += (string)rhs;
    return GetPointer(this);
  }

  nvStringStream *operator<<(uint rhs)
  {
    _buf += (string)rhs;
    return GetPointer(this);
  }

  nvStringStream *operator<<(long rhs)
  {
    _buf += (string)rhs;
    return GetPointer(this);
  }

  nvStringStream *operator<<(ulong rhs)
  {
    _buf += (string)rhs;
    return GetPointer(this);
  }

  nvStringStream *operator<<(bool rhs)
  {
    _buf += (string)rhs;
    return GetPointer(this);
  }

  nvStringStream *operator<<(datetime rhs)
  {
    _buf += (string)rhs;
    return GetPointer(this);
  }

  nvStringStream *operator<<(double rhs)
  {
    _buf += (string)rhs;
    return GetPointer(this);
  }

  nvStringStream *operator<<(const double &rhs[])
  {
    string res = "[";
    int num = ArraySize(rhs);
    for (int i = 0; i < num; ++i)
    {
      res += (string)rhs[i];
      if(i!=num-1)
        res += ", ";
    }
    res += "]";

    _buf += res;
    return GetPointer(this);
  }

};