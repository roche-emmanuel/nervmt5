#include <nerv/core.mqh>
#include <nerv/network/zmq_bind.mqh>

class nvZMQContext
{
protected:
  long _context;

protected:
  // Protected constructor and destructor:
  nvZMQContext(void)
  {
    _context = 0;
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
  
};
