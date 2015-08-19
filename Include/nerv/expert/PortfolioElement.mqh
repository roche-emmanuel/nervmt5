#include <nerv/core.mqh>

class nvPortfolioManager;

/*
Class: nvPortfolioElement

Base class representing an object that needs to access a portfolio manager
instance.
*/
class nvPortfolioElement : public nvObject
{
protected:
  nvPortfolioManager* _manager;

public:
  /*
    Class constructor.
  */
  nvPortfolioElement()
  {
    _manager = NULL;
  }

  /*
    Copy constructor
  */
  nvPortfolioElement(const nvPortfolioElement& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvPortfolioElement& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvPortfolioElement()
  {
    // No op.
  }

  /*
  Function: getManager
  
  Retrieve the portfolio manager object
  */
  nvPortfolioManager* getManager()
  {
    CHECK_RET(_manager,NULL,"Invalid portfolio manager");
    return _manager;
  }
  
  /*
  Function: setManager
  
  Assign the portfolio manager to this object
  */
  void setManager(nvPortfolioManager* manager)
  {
    CHECK(_manager==NULL,"Manager already assigned.");
    CHECK(manager!=NULL,"Invalid portfolio manager");
    _manager = manager;

    initialize();
  }
  
  /*
  Function: setManager
  
  Assign the portfolio manager by reference
  */
  void setManager(nvPortfolioManager& manager)
  {
    setManager(GetPointer(manager));
  }
  
  /*
  Function: initialize
  
  Method called jsut after the manager for this object is assigned.
  Does nothing by default. SHould by reimplemented in derived classes.
  */
  virtual void initialize()
  {
    // NO op.
  }
  
};
