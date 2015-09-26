#include <nerv/core.mqh>
#include <nerv/network/zmq_bind.mqh>

/*
Class: nvBinStream

Class used to encapsulate convertions to and from binary streams
*/
class nvBinStream : public nvObject
{
protected:
  char _data[];
  int _pos;

  char _char_arr[];
  int _int_arr[];
  double _double_arr[];

public:
  /*
    Class constructor.
  */
  nvBinStream()
  {
    init();
  }

  /*
    Copy constructor
  */
  nvBinStream(const nvBinStream& rhs)
  {
    init();
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvBinStream& rhs)
  {
    // TODO duplicate the data here.
    ArrayCopy( _data, rhs._data);
    _pos = rhs._pos;
  }

  /*
  Function: init
  
  Initialization method
  */
  void init()
  {
    ArrayResize( _char_arr, 1 );
    ArrayResize( _int_arr, 1 );
    ArrayResize( _double_arr, 1 );

    clear();
  }
  
  /*
    Class destructor.
  */
  ~nvBinStream()
  {
    clear();
  }

  /*
  Function: clear
  
  Reset the content of that stream completely
  */
  void clear()
  {
    ArrayResize( _data, 0 );
    _pos = 0;
  }
  
  /*
  Function: resetPos
  
  Reset the position of cursor on this stream
  */
  void resetPos()
  {
    _pos = 0;
  }
  
  /*
  Function: size
  
  Retrieve the current size of the data buffer
  */
  int size() const
  {
    return ArraySize( _data );
  }
  
  /*
  Function: getBuffer
  
  Retrieve the data buffer
  */
  void getBuffer(uchar &buf[]) const
  {
    ArrayResize( buf, 0 );
    ArrayCopy( buf, _data );
  }
  
  /*
  Function: reserve
  
  Method called to allocate some space starting from the current position
  in the data buffer. will not do anything if we already have enough space in 
  the buffer
  */
  void reserve(int len)
  {
    int clen = ArraySize( _data );
    int needed = _pos + len;
    if(clen < needed) 
    {
      ArrayResize( _data, needed );
    }
  }

  nvBinStream *operator<<(const int &val)
  {
    int num = 4; 
    reserve(num);

    _int_arr[0] = val;

    long src = getMemAddress(_int_arr);
    long dest = getMemAddress(_data);

    memcpy(dest+_pos,src,num);    
    _pos += num;

    return THIS;
  }  
  
  nvBinStream *operator>>(int &val)
  {
    int num = 4;

    long dest = getMemAddress(_int_arr);
    long src = getMemAddress(_data);

    memcpy(dest,src+_pos,num);
    _pos += num;
    
    val = _int_arr[0];
    
    return THIS;
  }  

  nvBinStream *operator<<(const string &val)
  {
    int len = StringLen( val );
    this << len; // write the length.

    char ch[];
    CHECK_RET(StringToCharArray(val,ch,0,len)==len,NULL,"Cannot copy all the string elements.");

    // Copy the string data:
    ArrayCopy( _data, ch, _pos, 0, len );

    return THIS;
  }

  nvBinStream *operator>>(string &val)
  {
    int num = 0;
    this >> num; // Read the string length.

    char ch[];

    // copy the data in the char array:
    ArrayCopy( ch, _data, 0, _pos, num );
    _pos += num;

    val = CharArrayToString(ch);

    return THIS;
  }

  nvBinStream *operator<<(const double &val)
  {
    int num = 8; 
    reserve(num);

    _double_arr[0] = val;

    long src = getMemAddress(_double_arr);
    long dest = getMemAddress(_data);

    memcpy(dest+_pos,src,num);    
    _pos += num;

    return THIS;
  }  
  
  nvBinStream *operator>>(double &val)
  {
    int num = 8;

    long dest = getMemAddress(_double_arr);
    long src = getMemAddress(_data);

    memcpy(dest,src+_pos,num);
    _pos += num;
    
    val = _double_arr[0];
    
    return THIS;
  }  

  nvBinStream *operator<<(const char &val)
  {
    int num = 1; 
    reserve(num);

    _char_arr[0] = val;

    long src = getMemAddress(_char_arr);
    long dest = getMemAddress(_data);

    memcpy(dest+_pos,src,num);
    _pos += num;

    return THIS;
  }  
  
  nvBinStream *operator>>(char &val)
  {
    int num = 1;

    long dest = getMemAddress(_char_arr);
    long src = getMemAddress(_data);

    memcpy(dest,src+_pos,num);
    _pos += num;
    
    val = _char_arr[0];
    
    return THIS;
  }    

  nvBinStream *operator<<(const bool &val)
  {
    char tval = 1;
    char fval = 0;

    if(val) {
      this << tval;
    }
    else {
      this << fval;
    }
    
    return THIS;
  }

  nvBinStream *operator>>(bool &val)
  {
    char cval;
    this >> cval;
    val = cval!=0;
    
    return THIS;
  }
};
