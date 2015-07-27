#include <nerv/core.mqh>

/*
Class: nvPortfolioManager

This class represents the Portfolio manager of our expert implementation.
It is used as a singleton.
*/
class nvPortfolioManager : public nvObject
{
protected:
  // Following methods are protected to respect the singleton pattern

  /*
    Class constructor.
  */
  nvPortfolioManager()
  {
    // No op.
  }

  /*
    Copy constructor
  */
  nvPortfolioManager(const nvPortfolioManager& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvPortfolioManager& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvPortfolioManager()
  {
    // No op.
  }

public:
  // Retrieve the instance of this class:
  static nvPortfolioManager *instance()
  {
    static nvPortfolioManager singleton;
    return GetPointer(singleton);
  }

  /*
  Function: update
  
  Method called to update the complete state of this Portfolio Manager
  */
  void update()
  {
    logDEBUG(TimeLocal()<<": Updating Portfolio Manager.")
  }
  
};
