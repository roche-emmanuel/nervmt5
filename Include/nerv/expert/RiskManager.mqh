#include <nerv/core.mqh>

/*
Class: nvRiskManager

Component used to control the risk in the traders performed by all currency traders.
There is one copy of this element in the PortfolioManager
*/
class nvRiskManager : public nvObject
{
public:
  /*
    Class constructor.
  */
  nvRiskManager()
  {
    // No op.
  }

  /*
    Copy constructor
  */
  nvRiskManager(const nvRiskManager& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvRiskManager& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvRiskManager()
  {
    // No op.
  }
};
