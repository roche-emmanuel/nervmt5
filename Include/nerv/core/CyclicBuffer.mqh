#include <nerv/core.mqh>

/*
Class: nvCyclicBuffer

Cyclic buffer implementation
*/
class nvCyclicBuffer
{
public:
  double data[];
  int pos;

protected:
  int _count;
  int _size;

public:
  /*
    Class constructor.
  */
  nvCyclicBuffer(int size=1)
  {
    resize(size);
  }

  /*
    Copy constructor
  */
  nvCyclicBuffer(const nvCyclicBuffer& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvCyclicBuffer& rhs)
  {
    ArrayCopy( data, rhs.data );
    pos = rhs.pos;

    _count = rhs._count;
    _size = rhs._size;
  }

  /*
    Class destructor.
  */
  ~nvCyclicBuffer()
  {
    // No op.
  }

  /*
  Function: resize
  
  Resize the buffer
  */
  void resize(int size)
  {
    CHECK(size>=1,"Invalid size for cyclic buffer")
    ArrayResize( data, size );
    _size = size;
    reset();
  }

  /*
  Function: reset
  
  Reset the content of this buffer
  */
  void reset()
  {
    ArrayFill(data,0,_size,0.0);
    pos = 0;
    _count = 0;
  }
  
  /*
  Function: isFilled
  
  Method used to check if this buffer is isFilled
  */
  bool isFilled()
  {
    return _count >= _size;
  }
  
  /*
  Function: back
  
  Retrieve the back element in this buffer
  */
  double back()
  {
    return data[pos==0 ? _size-1 : pos-1];
  }
  
  /*
  Function: set_back
  
  Set the back value
  */
  void set_back(double val)
  {
    data[pos==0 ? _size-1 : pos-1] = val;
  }
  
  /*
  Function: front
  
  Retrieve the current front value
  */
  double front()
  {
    return data[pos];
  }
  
  /*
  Function: set_front
  
  Set the front value
  */
  void set_front(double val)
  {
    data[pos] = val;
  }
  
  /*
  Function: push_back
  
  Method to push a new element at the back of this buffer:
  */
  double push_back(double val)
  {    
    double prev = data[pos];
    data[pos] = val;

    pos = (pos+1)%_size;
    _count++;
    return prev;
  }
  
  /*
  Function: push_front
  
  Push a new element at the from of this buffer
  */
  double push_front(double val)
  {
    pos = pos==0 ? _size-1 : pos-1;
    double prev = data[pos];
    data[pos] = val;
    _count++;
    return prev;
  }
  
  /*
  Function: max
  
  Retrieve the maximum value in this buffer
  */
  double max()
  {
    double val = data[0];
    for(int i=1;i<_size;++i) {
      val = MathMax( val, data[i] );
    }
    return val;
  }
  
  /*
  Function: min
  
  Retrieve the min valud in this buffer
  */
  double min()
  {
    double val = data[0];
    for(int i=1;i<_size;++i) {
      val = MathMin( val, data[i] );
    }
    return val;    
  }

};
