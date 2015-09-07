#include <nerv/core.mqh>
#include <nerv/network/zmq_bind.mqh>
#include <nerv/network/ZMQContext.mqh>

/*
Class: nvZMQSocket

Class representing a ZMQ socket
*/
class nvZMQSocket : public nvObject
{
protected:
  long _socket;

public:
  /*
    Class constructor.
  */
  nvZMQSocket(int type)
  {
    _socket = 0;
    open(type);
  }

  /*
    Copy constructor
  */
  nvZMQSocket(const nvZMQSocket& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvZMQSocket& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvZMQSocket()
  {
    close();
  }

  /*
  Function: close
  
  Method used to close this socket:
  */
  void close()
  {
    // Release the opaque socket pointer here:
    if(_socket!=0)
    {
      // logDEBUG("Closing ZMQSocket.");
      int res = zmq_close(_socket);
      // logDEBUG("ZMQSocket closed.");
      if(res!=0)
      {
        THROW("Error in zmq_close(): error "<<zmq_errno());
      }
      _socket = 0;
    }    
  }
  
  /*
  Function: open
  
  Method used to open this socket
  */
  void open(int type)
  {
    close();

    // Ensure the context is initialized:
    nvZMQContext::instance().init();

    // Use the context to create a new socket opaque pointer:
    // note that this method will throw an error in case the socket cannot
    // be created.
    _socket = nvZMQContext::instance().createSocket(type);
  }
  
  /*
  Function: connect
  
  Methoc used to connect a socket to an end point
  */
  void connect(string endpoint)
  {
    CHECK(_socket!=0,"Invalid socket.")
    uchar ch[];
    StringToCharArray(endpoint,ch);

    int res = zmq_connect(_socket,ch);
    if(res!=0)
    {
      THROW("Error in zmq_connect(): error "<<zmq_errno());
    }
  }
  
  /*
  Function: bind
  
  Method used to bind a socket
  */
  void bind(string endpoint)
  {
    CHECK(_socket!=0,"Invalid socket.")
    uchar ch[];
    StringToCharArray(endpoint,ch);

    int res = zmq_bind(_socket,ch);
    if(res!=0)
    {
      THROW("Error in zmq_bind(): error "<<zmq_errno());
    }    
  }
  
  /*
  Function: simple_send
  
  Method used to send a char array on this socket
  */
  void simple_send(const char& data[])
  {
    CHECK(_socket!=0,"Invalid socket.")
    int len = ArraySize( data );
    if(len==0)
      return; // nothing to send.

    // Otherwise we try to send the data:
    int len2 = zmq_send(_socket,data,len,ZMQ_DONTWAIT);
    if (len2!=len) {
      THROW("Error in zmq_send(): error "<<zmq_errno());
    }
  }
  
  /*
  Function: simple_receive
  
  Method used to receive some data with a known size
  */
  void simple_receive(char &data[], int len)
  {
    CHECK(_socket!=0,"Invalid socket.")
    CHECK(len>0,"Invalid data length")
    ArrayResize( data, len );

    int res = zmq_recv(_socket,data,len,ZMQ_DONTWAIT);
    if (res==-1)
    {
      int err = zmq_errno();
      if(err!=EAGAIN) {
        THROW("Error in zmq_recv(): error: "<<err);
      }
    }
    else if(res!=len) {
      THROW("Error in zmq_recv(): array size mismatch: "<<res<<"!="<<len);
    }
  }
  
};

