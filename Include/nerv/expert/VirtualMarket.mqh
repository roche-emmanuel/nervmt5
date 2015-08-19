#include <nerv/core.mqh>
#include <nerv/expert/Market.mqh>

/*
Class: nvVirtualMarket

Class used to represent a virtual market evolving in parallel to the real market
but where the currency traders can perform trades with virtual money (and no real effect!)
*/
class nvVirtualMarket : public nvMarket
{
public:
  /*
    Class constructor.
  */
  nvVirtualMarket()
  {
    _marketType = MARKET_TYPE_VIRTUAL;
  }

  /*
    Copy constructor
  */
  nvVirtualMarket(const nvVirtualMarket& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvVirtualMarket& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvVirtualMarket()
  {
    // No op.
  }

  /*
  Function: doOpenPosition
  
  Method called to actually open a position on a given symbol on that market.
  Note that the stoploss value is given in number of points.
  */
  virtual bool doOpenPosition(nvDeal* deal, double sl = 0.0)
  {
    // Retrieve the current open price:
    nvPortfolioManager* man = getManager();
    datetime entryTime = man.getCurrentTime();

    // Also retrieve the price we had at that time:
    // Note that this might not be the latest time available on the real server!
    MqlRates rates[];
    CHECK_RET(CopyRates(deal.getSymbol(),PERIOD_M1,entryTime,1,rates)==1,false,"Cannot copy the rates at time: "<<entryTime);

    double price = rates[0].close;
    // TODO: should add some random tick generation system here.

    double point = nvGetPointSize(deal.getSymbol());

    if(deal.getOrderType()==ORDER_TYPE_BUY)
    {
      price += rates[0].spread*point;      
      deal.setStopLossPrice(price-sl*point);
    }
    else {
      deal.setStopLossPrice(price+sl*point);
    }

    deal.setEntryTime(entryTime);
    deal.setEntryPrice(price);

    // open the deal:
    deal.open();
    
    return true;
  }

  /*
  Function: doClosePosition
  
  Method called to actually close a position on a given symbol on that market.
  Must be reimplemented by derived classes.
  */
  virtual void doClosePosition(nvDeal* deal)
  {
    // Retrieve the current open price:
    nvPortfolioManager* man = getManager();
    datetime exitTime = man.getCurrentTime();

    // Also retrieve the price we had at that time:
    // Note that this might not be the latest time available on the real server!
    MqlRates rates[];
    CHECK(CopyRates(deal.getSymbol(),PERIOD_M1,exitTime,1,rates)==1,"Cannot copy the rates at time: "<<exitTime);

    double price = rates[0].close;
    // TODO: should add some random tick generation system here.

    double point = nvGetPointSize(deal.getSymbol());

    if(deal.getOrderType()==ORDER_TYPE_SELL)
    {
      price += rates[0].spread*point;      
    }

    deal.setExitTime(exitTime);
    deal.setExitPrice(price);

    deal.close(); // Needed to update the value of numPoints and profit.
  }  
};
