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
      int res = zmq_close(_socket);
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

    // Use the context to create a new socket opaque pointer:
    // note that this method will throw an error in case the socket cannot
    // be created.
    _socket = nvZMQContext::instance().createSocket(type);
  }
  
};

