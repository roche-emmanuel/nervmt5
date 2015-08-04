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

  // profit of this deal in the same currency as the balance:
  double _profit;

  // utilities of all traders when the deal is initialized:
  double _utilities[];

  // Utility of the trader owning this deal when it is initialized:
  double _traderUtility;

  // Utility efficiency when this deal is initialized:
  double _utilityEfficiency;

  // price when entering this deal:
  double _entryPrice;

  // datetime of the entry of this deal:
  datetime _entryTime;

  // pricewhen exiting this deal:
  double _exitPrice;

  // datetime of the exit of this deal:
  datetime _exitTime;

  // order type of this deal:
  ENUM_ORDER_TYPE _orderType;

  // Boolean to check if this deal is done or not:
  bool _isDone;

public:
  /*
    Class constructor.
  */
  nvDeal()
  {
    _traderID = INVALID_TRADER_ID; // invalid default value.
    _numPoints = 0.0; // No profit by default.
    _profit = 0.0;
    ArrayResize( _utilities, 0 ); // No utilities by default.
    _traderUtility = 0.0; // Default utility value.
    _utilityEfficiency = 1.0; // Default efficiency of the utility assignment.
    _entryPrice = 0.0;
    _entryTime = 0;
    _exitPrice = 0.0;
    _exitTime = 0;
    _orderType = 0;
    _isDone = false;
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
  
  /*
  Function: getProfit
  
  Retrieve the profit of this deal
  */
  double getProfit()
  {
    return _profit;
  }
  
  /*
  Function: setProfit
  
  Set the profit of this deal
  */
  void setProfit(double profit)
  {
    _profit = profit;
  }

  /*
  Function: getUtilities
  
  Retrieve all the utilities from all traders by the time
  this deal is initialized.
  */
  void getUtilities(double& arr[])
  {
    int num = ArraySize( _utilities );
    ArrayResize( arr, num );
    if(num>0)
    {
      CHECK(ArrayCopy(arr, _utilities)==num,"Could not copy all utilities elements.");
    }
  }

  /*
  Function: open
  
  Method called when this deal should be opened.
  This method we retrieve the current settings from the currency trader
  and portfolio manager.
  */
  void open(int id, ENUM_ORDER_TYPE orderType, double entryPrice, datetime entryTime)
  {
    CHECK(entryPrice>0.0 && entryTime>0,"Invalid entry price and/or time");

    _entryPrice = entryPrice;
    _entryTime = entryTime;
    _orderType = orderType;

    // Assign the trader ID:
    setTraderID(id);

    // We assume that the trader ID is available here:
    CHECK(_traderID!=INVALID_TRADER_ID,"Invalid trader ID in open.");

    nvPortfolioManager* man = nvPortfolioManager::instance();

    // Retrieve the corresponding trader:
    nvCurrencyTrader* ct = man.getCurrencyTraderByID(_traderID);
    CHECK(ct,"Invalid currency trader.");

    // Assign the current utility of the parent trader:
    _traderUtility = ct.getUtility();

    // also keep a ref on the utitity efficiency:
    _utilityEfficiency = man.getUtilityEfficiency();

    // Also keep a list of all current utilities:
    man.getUtilities(_utilities);
  }
  
  /*
  Function: close
  
  Method called to close this deal with a given price at a given time
  */
  void close(double exitPrice, datetime exitTime, double profit)
  {
    // Ensure that the deal was opened first:
    CHECK(_entryTime>0 && _entryPrice>0.0,"Cannot close not opened deal.");

    _exitPrice = exitPrice;
    _exitTime = exitTime;

    // Ensure that the timestamps are correct:
    CHECK(_entryTime<_exitTime,"Invalid entry/exit times");

    // At this point we can also compute the profit in number of points:
    _numPoints = _orderType==ORDER_TYPE_BUY ? _exitPrice - _entryPrice : _entryPrice - _exitPrice;

    // assign the profit value:
    _profit = profit;
    
    // Mark this deal as done:
    _isDone = true;
  }
  
  /*
  Function: isDone
  
  Check if this deal is done or not.
  */
  bool isDone()
  {
    return _isDone;
  }
  
  /*
  Function: getEntryPrice
  
  Retrieve the entry price of this deal
  */
  double getEntryPrice()
  {
    return _entryPrice;
  }
  
  /*
  Function: getEntryTime
  
  Retrieve the entry time of that deal
  */
  datetime getEntryTime()
  {
    return _entryTime;
  }
  
  /*
  Function: getExitPrice
  
  Retrieve the exit price of this deal:
  */
  double getExitPrice()
  {
    return _exitPrice;
  }
  
  /*
  Function: getExitTime
  
  Retrieve the exit time of this deal
  */
  datetime getExitTime()
  {
    return _exitTime;
  }
};
