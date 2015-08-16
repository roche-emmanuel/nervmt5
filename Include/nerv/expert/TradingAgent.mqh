#include <nerv/core.mqh>

/*
Class: nvTradingAgent

Class used as a base class to represent a trading agent in a given
currency trader.
*/
class nvTradingAgent : public nvObject
{
public:
  /*
    Class constructor.
  */
  nvTradingAgent()
  {
    // No op.
  }

  /*
    Copy constructor
  */
  nvTradingAgent(const nvTradingAgent& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvTradingAgent& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvTradingAgent()
  {
    // No op.
  }
};
