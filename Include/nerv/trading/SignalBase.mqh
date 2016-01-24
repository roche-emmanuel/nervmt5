#include <nerv/core.mqh>
#include <nerv/core/Object.mqh>

/*
Class: nvSignalBase

Base class representing a trader 
*/
class nvSignalBase : public nvObject
{
public:
  /*
    Class constructor.
  */
  nvSignalBase()
  {
  }

  /*
    Copy constructor
  */
  nvSignalBase(const nvSignalBase& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvSignalBase& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvSignalBase()
  {
  }

  virtual double getSignal()
  {
    return 0.0;
  }
};
