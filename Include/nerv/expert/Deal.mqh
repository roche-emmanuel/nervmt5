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

public:
  /*
    Class constructor.
  */
  nvDeal()
  {
    _traderID = INVALID_TRADER_ID; // invalid default value.
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
  
};
