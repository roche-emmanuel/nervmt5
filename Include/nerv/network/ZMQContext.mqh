#include <nerv/core.mqh>
#include <nerv/network/zmq_bind.mqh>

class nvZMQContext
{
protected:

protected:
  // Protected constructor and destructor:
  nvZMQContext(void)
  {

  };

  ~nvZMQContext(void)
  {

  };

public:
  // Retrieve the instance of this log manager:
  static nvZMQContext *instance()
  {
    static nvZMQContext singleton;
    return GetPointer(singleton);
  }

};
