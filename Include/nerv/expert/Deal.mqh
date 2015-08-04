#include <nerv/core.mqh>

#include <nerv/expert/PortfolioManager.mqh>

/*
Class: nvDeal

This class represents a deal that was just completed.
It will provide information on how many points we have in profit,
when the deal was entered and exited, the current weight of the corresponding
trader, etc...
*/
class nvDeal : public nvObject
{
protected:
  // ID of the trader owning this deal:
  int _traderID;

  // Number of points of profit received in this deal:
  double _numPoints;

public:
  /*
    Class constructor.
  */
  nvDeal()
  {
    _traderID = INVALID_TRADER_ID; // invalid default value.
    _numPoints = 0.0; // No profit by default.
  }

  /*
    Copy constructor
  */
  nvDeal(const nvDeal& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvDeal& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvDeal()
  {
    // No op.
  }

  /*
  Function: getTraderID
  
  Retrieve the ID of the trader owning this deal
  */
  int getTraderID()
  {
    return _traderID;
  }
  
  /*
  Function: setTraderID
  
  Assign the ID of the trader owning this deal
  */
  void setTraderID(int id)
  {
    // Here we should ensure that the corresponding trader exists:
    CHECK(nvPortfolioManager::instance().getCurrencyTraderByID(id)!=NULL,"Invalid trader ID");
    _traderID = id;
  }

  /*
  Function: getNumPoints
  
  Retrieve the number of points of profit for this deal
  */
  double getNumPoints()
  {
    return _numPoints;
  }
  
  /*
  Function: setNumPoints
  
  Set the number of points of profit for this deal.
  */
  void setNumPoints(double points)
  {
    _numPoints = points;
  }
  
  
};
