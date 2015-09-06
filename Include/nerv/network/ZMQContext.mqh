#include <nerv/core.mqh>
#include <nerv/network/zmq_bind.mqh>
#include <nerv/network/ZMQSocket.mqh>

class nvZMQContext
{
protected:
  long _context;

protected:
  // Protected constructor and destructor:
  nvZMQContext(void)
  {
    _context = 0;
    init();
  };

  ~nvZMQContext(void)
  {
    uninit();
  };

public:
  // Retrieve the instance of this log manager:
  static nvZMQContext *instance()
  {
    static nvZMQContext singleton;
    return GetPointer(singleton);
  }

  /*
  Function: init
  
  Initialize the context
  */
  void init()
  {
    // Should create a new context here:
    if(_context!=0)
      return; // already initialized, nothing to do.

    _context = zmq_ctx_new();
    if(_context==0)
    {
      THROW("Error in zmq_ctx_new(): error "<<zmq_errno());
    }    
  }
  

  /*
  Function: uninit
  
  Uninitialize the context
  */
  void uninit()
  {
    if(_context!=0)
    {
      int res = zmq_ctx_term(_context);
      if(res!=0)
      {
        THROW("Error in zmq_ctx_term(): error "<<zmq_errno());
      }
      _context = 0;
    }    
  }
  
  /*
  Function: createSocket
  
  Method used to create a new socket object
  */
  long createSocket(int type)
  {
    CHECK_RET(_context>0,0,"ZMQ is not initialized.");
    long socket = zmq_socket(_context,type);
    if(socket==0)
    {
      THROW("Error in zmq_socket(): error "<<zmq_errno());
    }

    return socket;
  }
  
};
