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

  // Store a message object
  zmq_msg_stream _msgObject;
  long _msg;

public:
  /*
    Class constructor.
  */
  nvZMQSocket(int type)
  {
    // Retrieve the address of the message object:
    _msg = getMemAddress(_msgObject.data);

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

    // Set linger to zero by default:
    setOption(ZMQ_LINGER,0);
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
  
  /*
  Function: send
  
  Method used to send a char array on this socket
  */
  void send(const char& data[], int flags = ZMQ_DONTWAIT)
  {
    CHECK(_socket!=0,"Invalid socket.")
    int len = ArraySize( data );
    if(len==0)
      return; // nothing to send.

    // Otherwise we try to send the data:
    int res = zmq_msg_init_size(_msg,len);
    if (res!=0)
    {
      THROW("Cannot init ZMQ message: error "<<zmq_errno());
    }

    // Copy the actual data into the message:
    long dest = zmq_msg_data(_msg);
    CHECK(dest!=0,"Invalid data address.");

    long src = getMemAddress(data);

    // logDEBUG("send: memcpy("<<dest<<","<<src<<","<<len<<")");
    memcpy(dest,src,len);
    // logDEBUG("send: memcpy done.");

    // Now we can send the message:
    int len2 = zmq_msg_send(_msg,_socket,flags);
    if (len2!=len) {
      THROW("Error in zmq_send(): error "<<zmq_errno());
    }

    // Close that message:
    res = zmq_msg_close(_msg);
    if(res!=0)
    {
      THROW("Cannot close ZMQ message: error "<<zmq_errno());      
    }
  }

  /*
  Function: receive
  
  Method used to receive a char array on this socket
  */
  int receive(char& data[], int flags = ZMQ_DONTWAIT)
  {
    CHECK_RET(_socket!=0,0,"Invalid socket.")

    // Prepare a message object:
    // Create a message object:
    int res = zmq_msg_init(_msg);
    if (res!=0)
    {
      THROW("Cannot init ZMQ message: error "<<zmq_errno());
    }

    int len = zmq_msg_recv(_msg,_socket,flags);
    if (len<0)
    {
      int err = zmq_errno();
      if(err!=EAGAIN) {
        THROW("Error in zmq_msg_recv(): error: "<<err);
      }
    }
    else if(len==0) {
      THROW("Error in zmq_msg_recv(): received a message with length 0.");
    }

    ArrayResize( data, MathMax(len,0) );

    if(len>0)
    {
      long dest = getMemAddress(data);
      long src = zmq_msg_data(_msg);

      // logDEBUG("receive: memcpy("<<dest<<","<<src<<","<<len<<")");
      memcpy(dest,src,len);
      // logDEBUG("send: memcpy done.");      
    }

    // Close that message:
    res = zmq_msg_close(_msg);
    if(res!=0)
    {
      THROW("Cannot close ZMQ message: error "<<zmq_errno());      
    }  

    return MathMax(len,0);
  }

  /*
  Function: setOption
  
  Method to set an option on this socket
  */
  void setOption(int id, int value)
  {
    CHECK(_socket!=0,"Invalid socket.")

    // Set an option as an integer:
    int32_stream opt;
    ArrayFill(opt.data,0,4,0);

    // Need to turn the int value into an array:
    int arr[1];
    arr[0] = value;

    long src = getMemAddress(arr);
    long dest = getMemAddress(opt.data);

    memcpy(dest,src,4);

    int res = zmq_setsockopt(_socket, id, opt.data, 4);
    if(res!=0)
    {
      THROW("Cannot set ZMQ socket option: error "<<zmq_errno());
    }
  }
  
  /*
  Function: sendString
  
  Helper method to send a string
  */
  void sendString(string msg, int flags = ZMQ_DONTWAIT)
  {
    // Convert the string to char array:
    uchar ch[];
    StringToCharArray(msg,ch,0,StringLen(msg));
    send(ch,flags);
  }
  
  /*
  Function: receiveString
  
  Helper method to receive a string
  */
  string receiveString(int flags = ZMQ_DONTWAIT)
  {
    char data[];
    int len = receive(data,flags);
    if(len==0)
    {
      return "";
    }

    return CharArrayToString(data,0,len);
  }
  
};

