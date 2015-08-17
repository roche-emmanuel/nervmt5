#include <nerv/core.mqh>

/*
Class: nvAgentFactory

Factory class used to create different types of trading agents.
*/
class nvAgentFactory : public nvObject
{
public:
  /*
    Class constructor.
  */
  nvAgentFactory()
  {
    // No op.
  }

  /*
    Copy constructor
  */
  nvAgentFactory(const nvAgentFactory& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvAgentFactory& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvAgentFactory()
  {
    // No op.
  }
};
