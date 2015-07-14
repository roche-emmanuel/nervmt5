#include <nerv/core.mqh>

/*
Class: nvTrader

Simple class for the implementation of the basic trader functions
*/
class nvTrader : public nvObject
{
protected:
  nvSecurity _security;
  
public:
  /*
    Class constructor.
  */
  nvTrader(const nvSecurity& sec)
  {
    _security = sec;
  }

  /*
    Class destructor.
  */
  ~nvTrader()
  {
    // No op.
  }
}
