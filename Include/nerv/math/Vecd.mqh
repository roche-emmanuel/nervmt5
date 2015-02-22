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
  bool _dynamic;
  int _reserveSize;

public:
  /** Vector constructor:
  \param len: length of the vector.
  \param val: default element value.
  */
  nvVecd(uint len = 0, double val = 0.0, bool dynamic = false)
  {
    resize(len,val,dynamic);
  };

  nvVecd(const nvVecd &rhs)
  {
    _len = rhs._len;
    _dynamic = rhs._dynamic;
    _reserveSize = rhs._reserveSize;

    if (_len > 0)
    {
      int count = ArrayCopy(_data, rhs._data, 0, 0);
      CHECK(count == _len, "Invalid array copy count: " << count);
    }
  }

  nvVecd(const double &arr[], bool dynamic = false)
  {
    _len = ArraySize(arr);
    CHECK(_len > 0, "Invalid vector length.");
    _dynamic = dynamic;
    _reserveSize = _dynamic ? 1000 : 0;
    int count = ArrayCopy(_data, arr, 0, 0);
    CHECK(count == _len, "Invalid array copy count: " << count);
  }

  nvVecd *operator=(const nvVecd &rhs)
  {
    _len = rhs._len;
    _dynamic = rhs._dynamic;
    _reserveSize = rhs._reserveSize;
    CHECK(ArrayResize(_data, _len, _reserveSize) == _len, "Invalid result for ArrayResize()");

    int count = ArrayCopy(_data, rhs._data, 0, 0);
    CHECK(count == _len, "Invalid array copy count: " << count);
    return GetPointer(this);
  }

  nvVecd *operator=(const double &rhs[])
  {
    _len = ArraySize(rhs);
    _dynamic = false;
    _reserveSize = 0;
    CHECK(ArrayResize(_data, _len, _reserveSize) == _len, "Invalid result for ArrayResize()");

    int count = ArrayCopy(_data, rhs, 0, 0);
    CHECK(count == _len, "Invalid array copy count: " << count);
    return GetPointer(this);
  }

  ~nvVecd(void)
  {
  };

  void resize(uint len = 0, double val = 0.0, bool dynamic = false)
  {
    _len = len;

    // Create a dynamic vector if its length is set to zero.
    _dynamic = _len == 0 || dynamic;
    _reserveSize = _dynamic ? 1000 : 0;

    CHECK(ArrayResize(_data, len, _reserveSize) == len, "Invalid result for ArrayResize()");

    // Assign the default value:
    if (_len > 0)
      ArrayFill(_data, 0, _len, val);
  }

  uint size() const
  {
    return _len;
  }

  double at(const uint index) const
  {
    CHECK(index < _len, "Out of range index: " << index)
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
    CHECK(index < _len, "Out of range index: " << index)
    _data[index] = val;
  }

  void set(const uint index, const nvVecd &rhs)
  {
    CHECK(index + rhs.size() <= _len, "Cannot inject too long sub vector. index=" << index << ", len=" << _len << ", sublen=" << rhs.size());
    CHECK(ArrayCopy(_data, rhs._data, index, 0) == rhs.size(), "Cannot copy all the elements from source vector.");
  }

  bool operator==(const nvVecd &rhs) const
  {
    if (_len != rhs._len)
      return false;

    for (uint i = 0; i < _len; ++i)
    {
      if (_data[i] != rhs._data[i])
        return false;
    }

    return true;
  }

  bool operator!=(const nvVecd &rhs) const
  {
    return !(this == rhs);
  }

  nvVecd *operator+=(const nvVecd &rhs)
  {
    CHECK(_len == rhs._len, "Mismatch of lengths: " << _len << "!=" << rhs._len);

    for (uint i = 0; i < _len; ++i)
    {
      _data[i] += rhs._data[i];
    }
    return GetPointer(this);
  }

  nvVecd operator+(const nvVecd &rhs) const
  {
    nvVecd res(this);
    res += rhs;
    return res;
  }

  nvVecd *operator+=(double val)
  {
    for (uint i = 0; i < _len; ++i)
    {
      _data[i] += val;
    }
    return GetPointer(this);
  }

  nvVecd operator+(double val) const
  {
    nvVecd res(this);
    res += val;
    return res;
  }

  nvVecd *operator-=(const nvVecd &rhs)
  {
    CHECK(_len == rhs._len, "Mismatch of lengths: " << _len << "!=" << rhs._len);

    for (uint i = 0; i < _len; ++i)
    {
      _data[i] -= rhs._data[i];
    }
    return GetPointer(this);
  }

  nvVecd operator-(const nvVecd &rhs) const
  {
    nvVecd res(this);
    res -= rhs;
    return res;
  }

  nvVecd *operator-=(double val)
  {
    for (uint i = 0; i < _len; ++i)
    {
      _data[i] -= val;
    }
    return GetPointer(this);
  }

  nvVecd operator-(double val) const
  {
    nvVecd res(this);
    res -= val;
    return res;
  }

  nvVecd operator-() const
  {
    nvVecd res(this);
    for (uint i = 0; i < _len; ++i)
    {
      res._data[i] = -res._data[i];
    }
    return res;
  }

  nvVecd *operator*=(double val)
  {
    for (uint i = 0; i < _len; ++i)
    {
      _data[i] *= val;
    }
    return GetPointer(this);
  }

  nvVecd operator*(double val) const
  {
    nvVecd res(this);
    res *= val;
    return res;
  }

  nvVecd *operator/=(double val)
  {
    CHECK(val != 0.0, "Cannot divide by zero.");
    for (uint i = 0; i < _len; ++i)
    {
      _data[i] /= val;
    }
    return GetPointer(this);
  }

  nvVecd operator/(double val) const
  {
    nvVecd res(this);
    res /= val;
    return res;
  }

  double operator*(const nvVecd &rhs) const
  {
    CHECK(_len == rhs._len, "Mismatch of lengths: " << _len << "!=" << rhs._len);
    double res = 0.0;
    for (uint i = 0; i < _len; ++i)
    {
      res += _data[i] * rhs._data[i];
    }
    return res;
  }

  double operator*(const double &rhs[]) const
  {
    int arrlen = ArraySize(rhs);
    CHECK(_len == arrlen, "Mismatch of lengths: " << _len << "!=" << arrlen);
    double res = 0.0;
    for (uint i = 0; i < _len; ++i)
    {
      res += _data[i] * rhs[i];
    }
    return res;
  }

  double push_back(double val)
  {
    if (_dynamic)
    {
      _len++;
      CHECK(ArrayResize(_data, _len, _reserveSize) == _len, "Invalid resize operation.");
      _data[_len - 1] = val;
      return 0.0;
    }
    else
    {
      double res = _data[0];
      int count = ArrayCopy(_data, _data, 0, 1, _len - 1);
      CHECK(count == _len - 1, "Invalid array copy count: " << count);
      _data[_len - 1] = val;
      return res;
    }
  }

  double pop_back()
  {
    CHECK(_dynamic, "Cannot pop from non dynamic vector.");
    CHECK(_len > 0, "Cannot pop from empty vector.");

    double val = _data[_len - 1];
    _len--;
    CHECK(ArrayResize(_data, _len, _reserveSize) == _len, "Invalid resize operation.");
    return val;
  }

  double pop_front()
  {
    CHECK(_dynamic, "Cannot pop from non dynamic vector.");
    CHECK(_len > 0, "Cannot pop from empty vector.");

    double val = _data[0];
    // Copy the data at the back in the front:
    int count = ArrayCopy(_data, _data, 0, 1, _len - 1);
    CHECK(count == _len - 1, "Invalid array copy count: " << count);

    _len--;
    CHECK(ArrayResize(_data, _len, _reserveSize) == _len, "Invalid resize operation.");
    return val;
  }

  double push_front(double val)
  {
    if (_dynamic)
    {
      _len++;
      CHECK(ArrayResize(_data, _len, _reserveSize) == _len, "Invalid resize operation.");

      // Move the existing elements at the back of the vector:
      int count = ArrayCopy(_data, _data, 1, 0, _len - 1);
      CHECK(count == _len - 1, "Invalid array copy count: " << count);
      _data[0] = val;
      return 0.0;
    }
    else
    {
      double res = _data[_len - 1];
      int count = ArrayCopy(_data, _data, 1, 0, _len - 1);
      CHECK(count == _len - 1, "Invalid array copy count: " << count);
      _data[0] = val;
      return res;
    }
  }

  string toString() const
  {
    string res = "Vecd(";
    for (uint i = 0; i < _len; ++i)
    {
      res += (string)_data[i];
      if (i < _len - 1)
        res += ",";
    }
    res += ")";
    return res;
  }

  double norm2() const
  {
    return this * this;
  }

  double norm() const
  {
    return MathSqrt(norm2());
  }

  double normalize(double newNorm = 1.0)
  {
    // compute the current norm:
    double n = norm();
    if (n == 0.0)
      return n; // Do not try to divide by zero in that case.

    this *= (newNorm / n);

    return n;
  }

  double front() const
  {
    CHECK(_len > 0, "Cannot retrieve front with length " << _len);
    return _data[0];
  }

  double back() const
  {
    CHECK(_len > 0, "Cannot retrieve back with length " << _len);
    return _data[_len - 1];
  }

  void randomize(double mini, double maxi)
  {
    for (uint i = 0; i < _len; ++i)
    {
      _data[i] = nv_random_real(mini, maxi);
    }
  }

  double min() const
  {
    CHECK(_len > 0, "Cannot compute min with length " << _len);
    double val = _data[0];
    for (uint i = 1; i < _len; ++i)
    {
      val = MathMin(val, _data[i]);
    }
    return val;
  }

  double max() const
  {
    CHECK(_len > 0, "Cannot compute max with length " << _len);
    double val = _data[0];
    for (uint i = 1; i < _len; ++i)
    {
      val = MathMax(val, _data[i]);
    }
    return val;
  }

  double mean() const
  {
    CHECK(_len > 0, "Cannot compute mean with length " << _len);

    double val = 0.0;
    for (uint i = 0; i < _len; ++i)
    {
      val += _data[i];
    }

    val /= _len;
    return val;
  }

  double deviation() const
  {
    CHECK(_len >= 2, "Cannot compute deviation with length " << _len);

    double m = mean();
    double dev = norm2();
    dev /= (_len-1);

    dev -= m * m;
    dev = MathSqrt(dev);
    return dev;
  }

  bool valid() const
  {
    return _len > 0;
  }

  double EMA(double alpha) const
  {
    CHECK(_len > 0, "Cannot compute EMA with length " << _len);
    CHECK(0.0<alpha && alpha < 1.0,"Invalid value for alpha coeff: "<<alpha);

    double val = _data[0];
    for(uint i=1;i<_len;++i)
    {
      val = alpha * _data[i] + (1.0 - alpha) * val;
    }
    
    return val;
  }

  void fill(double val) {
    for(uint i=0;i<_len;++i)
    {
      _data[i] = val;
    }
  }

  nvVecd subvec(uint index, uint len) const
  {
    CHECK(len>0,"Invalid length for sub vector.");
    CHECK(index+len-1<_len,"Out of range access for subvector");
    nvVecd res(len);
    CHECK(ArrayCopy(res._data, _data, 0, index, len)==len,"Invalid result for Array copy");
    return res;
  }

  nvVecd stdnormalize() const
  {
    double dev = deviation();
    return (this - mean())/(dev==0.0 ? 1.0 : dev);
  }

  nvVecd mult(const nvVecd& rhs) const
  {
    CHECK(_len==rhs._len,"Mismatch in lengths");
    nvVecd res(this);
    for(uint i=0;i<_len;++i)
    {
      res._data[i] *= rhs._data[i];
    }
    return res;
  }

  void toArray(double& arr[]) const
  {
    CHECK(ArrayResize(arr,_len)==_len,"Invalid Array resize result.");
    CHECK(ArrayCopy(arr,_data,0,0)==_len,"Invalid array copy result.");
  }
};
