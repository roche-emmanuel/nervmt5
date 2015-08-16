#include <nerv/core.mqh>

#include <nerv/expert/PortfolioManager.mqh>
#include <nerv/expert/Deal.mqh>

/*
Class: nvCurrencyTrader

This class represents a trader that will operate on a fixed currency.
*/
class nvCurrencyTrader : public nvObject
{
protected:
  string _symbol;
  
  // The weight that should be assigned to this trader
  // when performing the "lot sizing" operation for a deal
  // compared to the other traders. The value should be in the 
  // range [0,1]
  double _weight;

  /*
  Utility value for this currency trader: determine how efficiency this
  trader is in generating profits instead of losses.
  Default value will be 0.0, indicating no bias towards profits or losses.
  Then positive values should indicates that this currency trader is generating
  profits whereas negative values would indicate losses.
  */
  double _utility;

  // Unique ID used to identify this trader:
  int _id;

  // List of past deals executed byt this trader:
  nvDeal* _previousDeals[];

public:
  /*
    Class constructor.
  */
  nvCurrencyTrader(string symbol)
  {
    // Store the symbol assigned to this trader:
    _symbol = symbol;

    // Initial weight value:
    _weight = 0.0;
    
    // Set default utility value:
    _utility = 0.0;

    // Retrieve a new unique ID for this trader from the PortfolioManager:
    _id = nvPortfolioManager::instance().getNewID();

    // Initialize the previous deals array:
    ArrayResize( _previousDeals, 0 );
  }

  /*
    Copy constructor
  */
  nvCurrencyTrader(const nvCurrencyTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    assignment operator
  */
  void operator=(const nvCurrencyTrader& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvCurrencyTrader()
  {
    // On deletion we should release all the deals contained in this trader:
    int num = ArraySize( _previousDeals );
    for(int i=0;i<num;++i)
    {
      RELEASE_PTR(_previousDeals[i]);
    }
    ArrayResize( _previousDeals, 0 );
  }

  /*
  Function: getSymbol
  
  Retrieve the symbol corresponding to this trader.
  THe symbol is used as a unique name for the trader.
  */
  string getSymbol()
  {
    return _symbol;
  }
  
  /*
  Function: setWeight
  
  Set the weight value of this trader
  */
  void setWeight(double val)
  {
    CHECK(val>=0.0 && val<=1.0,"Invalid weight value: "<<val)
    _weight = val;
  }

  /*
  Function: getWeight
  
  Retrieve the weight currently assigned to this trader
  */
  double getWeight()
  {
    return _weight;
  }
  
  /*
  Function: getUtility
  
  Retrieve the current utility value of this trader
  */
  double getUtility()
  {
    return _utility;
  }
  
  /*
  Function: getID
  
  Retrieve the unique ID assigned to this trader.
  */
  int getID()
  {
    return _id;
  }

  /*
  Function: update
  
  Method called to update the complete state of this Portfolio Manager
  */
  void update()
  {
    logDEBUG(TimeLocal()<<": Updating CurrencyTrader.")
  }

  /*
  Function: onDeal
  
  Method called each time a new deal owned by this trader is completed.
  */
  void onDeal(nvDeal* deal)
  {
    // Ensure this deal is valid:
    CHECK(deal!=NULL,"Invalid deal pointer.");
    CHECK(deal.getTraderID()==_id,"Invalid deal trader ID: "<<deal.getTraderID());
    CHECK(deal.isDone(),"Received not done deal");

    // We add this new deal to the previous deals list:
    int num = ArraySize( _previousDeals );
    if(num<TRADER_MAX_NUM_DEALS)
    {
      // We can just push the new deal:
      ArrayResize( _previousDeals, num+1 );
      _previousDeals[num] = deal;
    }
    else 
    {
      // We should not resize the array, but instead, pop
      // the oldest deal (and delete it in the process)
      nvDeal* old = _previousDeals[0];
      CHECK(ArrayCopy( _previousDeals, _previousDeals, 0, 1, num-1 )==num-1,"Invalid result for array copy operation");
      RELEASE_PTR(old);
      _previousDeals[num-1] = deal;
    }

    // Notify the portfolio manager there is a new profit sample:
    nvPortfolioManager::instance().addProfitSample(deal.getNominalProfit(),deal.getTraderUtility());

    // Now we should update the utility of this trader:
    updateUtility();
  }
  
  /*
  Function: computeProfitUtility
  
  Method used to compute the profit based utility value
  */
  double computeProfitUtility(datetime startTime, datetime stopTime)
  {
    int num = ArraySize( _previousDeals );
    nvDeal* ptr = NULL;
    datetime dtime;
    int dcount = 0;
    double sum = 0.0;
    double dd = 0.0; // drawdown deviation.
    double profit;
    double delta;
    datetime lastTime = 0;

    for(int i=0;i<num;++i)
    {
      ptr = _previousDeals[i];
      dtime = ptr.getExitTime();

      if(startTime <= dtime && dtime <= stopTime)
      {
        // Increment the count of deals taken into account:
        dcount++; 
        
        // Note: we use the nominal profit here, because the computation of the utility
        // should be unbiased, and thus should not consider the actual weight that was given to 
        // the trader when performing that deal. Instead, it should compute the utility as if 
        // the trader was constantly assigned a weight of 1.0:
        // profit = ptr.getProfit();
        profit = ptr.getNominalProfit();
        
        // compute the elapsed time since the last trade (in hours)
        delta = (double)(dtime - (lastTime==0 ? ptr.getEntryTime() : lastTime))/3600.0;
        CHECK_RET(delta>0.0,0.0,"Detected invalid deal duration.");

        // Now we compute the profit per unit of time (eg. per hour in this case):
        profit /= delta;

        sum += profit;
        if(profit<0.0)
        {
          // add the square of the profit value to the dd:
          dd += profit*profit;
        }
      }

      // Update the value of the lastTime with the exitTime of the current deal:
      // So that we can integrate the trading frequency into the utility loop above:
      lastTime = dtime;
    }

    // If there is deal in the target period the we cannot compute anything:
    if(dcount==0)
    {
      logDEBUG("Utility computation: no deal found in period from "<<startTime<<" to "<<stopTime);
      return 0.0;
    }

    // Once we have iterated on all deals we may return the utility value:
    // Computed here as a DDR ratio:
    // Note that we add +1.0 in the denominator here to ensure that this ratio is
    // always defined even if we have no negative profit. And the value of 1 correspond to
    // 1 unit of the balance currency which is quite close to the minimal drawdown deviation that could
    // be observed, and those the drawdown part of the denom will still have its full range of effect.
    return (sum/(double)dcount)/(1.0+MathSqrt(dd));
  }
  
  /*
  Function: updateUtility
  
  Update the utility of this trader using the deal history:
  */
  void updateUtility()
  {
    nvPortfolioManager* man = nvPortfolioManager::instance();

    // We should consider only a fixed period of time in the past to perform the utility computation
    // this duration is retrieved from the portfolio manager itself,
    // as a number of seconds.
    int duration = man.getUtilityWindowSize();

    // We use the current server time as reference, and we compute the starting point of the window
    // from that:
    datetime stopTime = TimeCurrent();
    datetime startTime = stopTime-duration;

    // We now iterate in the deal history, and we compute the utility using only the deals that finished in that time
    // frame:
    _utility = computeProfitUtility(startTime,stopTime);

    // Once the utility value is updated,
    // we should request a weight update from the portfolio manager:
    man.updateWeights();
  }
  
  /*
  Function: collectDeals
  
  Method called to retrieve a list of deals from this currency trader
  given a specific time window.

  Note that this method will return the number of deals collected.
  */
  int collectDeals(nvDeal* &arr[],datetime startTime, datetime stopTime)
  {
    int num = ArraySize( _previousDeals );
    nvDeal* ptr = NULL;

    int count = 0;

    for(int i=0;i<num;++i)
    {
      ptr = _previousDeals[i];

      if(startTime <= ptr.getEntryTime() && ptr.getExitTime() <= stopTime)
      {
        count++;
        int size = ArraySize( arr );
        ArrayResize( arr, size+1 );
        arr[size] = ptr;
      }
    }

    return count;
  }
  
};
