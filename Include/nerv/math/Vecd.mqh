//+------------------------------------------------------------------+
//|                                                          Log.mqh |
//|                                         Copyright 2015, NervTech |
//|                                https://wiki.singularityworld.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, NervTech"
#property link      "https://wiki.singularityworld.net"

#include <nerv/core.mqh>

class nvVecd : public nvObject
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

    // Assign the default value:
    ArrayFill(_data, 0, _len, val);
  };

  nvVecd(const nvVecd& rhs)
  {
    _len = rhs._len;
    int count = ArrayCopy(_data,rhs._data,0,0);
    CHECK(count==_len,"Invalid array copy count: "<<count);
  }

  nvVecd(const double& arr[])
  {
    _len = ArraySize(arr);
    CHECK(_len > 0, "Invalid vector length.");    
    int count = ArrayCopy(_data,arr,0,0);    
    CHECK(count==_len,"Invalid array copy count: "<<count);
  }

  nvVecd* operator=(const nvVecd& rhs)
  {
    CHECK(_len==rhs._len,"Mismatch in vector lengths");
    int count = ArrayCopy(_data,rhs._data,0,0);    
    CHECK(count==_len,"Invalid array copy count: "<<count);
    return GetPointer(this);    
  }

  ~nvVecd(void)
  {
  };

  uint size() const
  {
    return _len;
  }

  double at(const uint index) const
  {
    CHECK(index < _len, "Out of range index: " <<index)
    return _data[index];
  }

  double get(const uint index) const
  {
    return (at(index));
  }

  double operator[](const uint index) const
  {
    return (at(index));
  }

  void set(const uint index, double val)
  {
    CHECK(index < _len, "Out of range index: " <<index)
    _data[index] = val;
  }

  void set(const uint index, const nvVecd& rhs)
  {
    CHECK(index+rhs.size()<=_len,"Cannot inject too long sub vector. index="<<index<<", len="<<_len<<", sublen="<<rhs.size());
    CHECK(ArrayCopy(_data,rhs._data,index,0)==rhs.size(),"Cannot copy all the elements from source vector.");
  }

  bool operator==(const nvVecd &rhs) const
  {
    if(_len!=rhs._len)
      return false;

    for(uint i=0;i<_len;++i) {
      if(_data[i]!=rhs._data[i])
        return false;
    }

    return true;
  }

  bool operator!=(const nvVecd& rhs) const
  {
    return !(this==rhs);
  }

  nvVecd* operator+=(const nvVecd& rhs)
  {
    CHECK(_len==rhs._len,"Mismatch of lengths: "<<_len<<"!="<<rhs._len);

    for(uint i=0;i<_len;++i) {
      _data[i] += rhs._data[i];
    }
    return GetPointer(this);
  }

  nvVecd operator+(const nvVecd& rhs) const
  {
    nvVecd res(this);
    res += rhs;
    return res;
  }

  nvVecd* operator-=(const nvVecd& rhs)
  {
    CHECK(_len==rhs._len,"Mismatch of lengths: "<<_len<<"!="<<rhs._len);

    for(uint i=0;i<_len;++i) {
      _data[i] -= rhs._data[i];
    }
    return GetPointer(this);
  }

  nvVecd operator-(const nvVecd& rhs) const
  {
    nvVecd res(this);
    res -= rhs;
    return res;
  }

  nvVecd operator-() const
  {
    nvVecd res(this);
    for(uint i=0;i<_len;++i) {
      res._data[i] = -res._data[i];
    }
    return res;
  }

  nvVecd* operator*=(double val)
  {
    for(uint i=0;i<_len;++i) {
      _data[i] *= val;
    }
    return GetPointer(this);
  }

  nvVecd operator*(double val) const
  {
    nvVecd res(this);
    res*=val;
    return res;
  }

  nvVecd* operator/=(double val)
  {
    CHECK(val!=0.0,"Cannot divide by zero.");
    for(uint i=0;i<_len;++i) {
      _data[i] /= val;
    }
    return GetPointer(this);
  }

  nvVecd operator/(double val) const
  {
    nvVecd res(this);
    res/=val;
    return res;
  }

  double operator*(const nvVecd& rhs) const
  {
    CHECK(_len==rhs._len,"Mismatch of lengths: "<<_len<<"!="<<rhs._len);
    double res = 0.0;
    for(uint i=0;i<_len;++i) {
      res += _data[i]*rhs._data[i];
    }
    return res;
  }

  double push_back(double val)
  {
    double res =_data[0];
    int count = ArrayCopy(_data,_data,0,1,_len-1);
    CHECK(count==_len-1,"Invalid array copy count: "<<count);
    _data[_len-1]=val;
    return res;
  }

  double push_front(double val)
  {
    double res =_data[_len-1];
    int count = ArrayCopy(_data,_data,1,0,_len-1);
    CHECK(count==_len-1,"Invalid array copy count: "<<count);
    _data[0]=val;
    return res;
  }

  string toString() const
  {
    string res = "Vecd(";
    for(uint i=0;i<_len;++i) {
      res += (string)_data[i];
      if(i<_len-1)
        res += ",";
    }
    res += ")";
    return res;
  }

  double norm2() const
  {
    return this*this;
  }

  double norm() const
  {
    return MathSqrt(norm2());
  }

  double normalize(double newNorm = 1.0)
  {
    // compute the current norm:
    double n = norm();
    if(n==0.0)
      return n; // Do not try to divide by zero in that case.

    this *= (newNorm/n);

    return n;
  }

  double front() const
  {
    return _data[0];
  }

  double back() const
  {
    return _data[_len-1];
  }

  void randomize(double mini, double maxi)
  {
    for(uint i=0;i<_len;++i)
    {
      _data[i] = nv_random_real(mini,maxi);
    }
  }
};
