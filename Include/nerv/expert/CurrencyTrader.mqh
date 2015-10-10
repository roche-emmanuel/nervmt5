#include <nerv/core.mqh>

#include <nerv/expert/PortfolioElement.mqh>
#include <nerv/expert/PortfolioManager.mqh>
#include <nerv/expert/Deal.mqh>
#include <nerv/utils.mqh>
#include <nerv/expert/TradingAgent.mqh>
#include <nerv/expert/DecisionComposer.mqh>
#include <nerv/expert/DecisionComposerFactory.mqh>
#include <nerv/expert/Market.mqh>

/*
Class: nvCurrencyTrader

This class represents a trader that will operate on a fixed currency.
*/
class nvCurrencyTrader : public nvPortfolioElement
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

  // List of entry trading agents:
  nvTradingAgent* _entryAgents[];
  
  // decisions associated to the entry agents:
  double _entryDecisions[];

  // List of exit trading agents:
  nvTradingAgent* _exitAgents[];

  // decisions associated to the exit agents:
  double _exitDecisions[];

  // Entry decision composer:
  nvDecisionComposer* _entryDecisionComposer;

  // Exit decision composer:
  nvDecisionComposer* _exitDecisionComposer;

  // Current market type for this trader:
  MarketType _marketType;

  // Number of deals received by this currency trader:
  int _dealCount;

public:
  /*
    Class constructor.
  */
  nvCurrencyTrader()
  {
    _symbol = "";

    // Initial weight value:
    _weight = 0.0;
    
    // Set default utility value:
    _utility = 0.0;

    // Initialize the deal count:
    _dealCount = 0;
    
    // By default we are on the real market:
    _marketType = MARKET_TYPE_UNKNOWN;

    // No ID by default.
    _id = 0;

    // Initialize the previous deals array:
    ArrayResize( _previousDeals, 0 );
  }

  /*
  Function: setSymbol
  
  Assign the symbol of this currency trader. Can only be called once.
  */
  void setSymbol(string symbol)
  {
    CHECK(_symbol=="","Symbol already assigned.")
    CHECK(nvIsSymbolValid(symbol),"Invalid symbol detected: "<<symbol);
    _symbol = symbol;

    // Ensure that the symbol is selected in the market watch window:
    SymbolSelect(symbol,true);
  }
  
  /*
  Function: initialize
  
  Method call to initialize the content of this currency trader
  */
  virtual void initialize()
  {
    // Retrieve a new unique ID for this trader from the PortfolioManager:
    _id = getManager().getNewID();

    // Setup the market type:
    setMarketType(MARKET_TYPE_REAL);

    // Build the decision composers here:
    nvDecisionComposerFactory* factory = getManager().getDecisionComposerFactory();
    
    _entryDecisionComposer = factory.createEntryComposer(THIS);
    CHECK(_entryDecisionComposer!=NULL,"Cannot create entry decision composer.");

    _exitDecisionComposer = factory.createExitComposer(THIS);
    CHECK(_exitDecisionComposer!=NULL,"Cannot create exit decision composer.");    
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
    nvReleaseObjects(_previousDeals);

    // Release all the agents contained in this trader:
    nvReleaseObjects(_entryAgents);
    nvReleaseObjects(_exitAgents);

    // Release the decision composers:
    RELEASE_PTR(_entryDecisionComposer);
    RELEASE_PTR(_exitDecisionComposer);
  }

  /*
  Function: getDealCount
  
  Retrieve the number of deals received by this currency trader
  */
  int getDealCount()
  {
    return _dealCount;
  }
  
  /*
  Function: getPreviousDealCount
  
  Retrieve the number of recent deals, eg. the size of the _previousDeals array
  */
  int getPreviousDealCount()
  {
    return ArraySize( _previousDeals );
  }
  
  /*
  Function: getPreviousDeal
  
  Retrieve the recent deal by index using a time series retrieval system
  */
  nvDeal* getPreviousDeal(int index)
  {
    int num = ArraySize( _previousDeals );
    CHECK_RET(num>0 && index<num,NULL,"Invalid index to retrieve recent deal: "<<index);
    return _previousDeals[num-1-index];
  }
  
  /*
  Function: getMarketType
  
  Retrieve the current market type for this object.
  */
  MarketType getMarketType()
  {
    return _marketType;
  }
  
  /*
  Function: setMarketType
  
  Assign the current market type for this object.
  */
  void setMarketType(MarketType mode)
  {
    CHECK(mode!=MARKET_TYPE_UNKNOWN,"Cannot assign unknown trader mode.");

    if(mode == _marketType)
    {
      // nothing to change in that case:
      return;
    }

    // First we must ensure that we have no open position left
    // on either the real or the virtual market
    nvMarket* market = getManager().getMarket(MARKET_TYPE_REAL);
    market.closePosition(_symbol);
    market = getManager().getMarket(MARKET_TYPE_VIRTUAL);
    market.closePosition(_symbol);

    // Assign the new mode:
    _marketType = mode;
  }
  
  /*
  Function: addTradingAgent
  
  Append an agent to the list of agent contained in this currency trader
  Can be either an entry agent or an exit agent.
  */
  void addTradingAgent(nvTradingAgent* agent, AgentCapabilities caps)
  {
    CHECK(agent!=NULL,"Invalid trading agent.")
    if(caps==TRADE_AGENT_ENTRY)
    {
      CHECK(agent.getCapabilities() & TRADE_AGENT_ENTRY,"Invalid trading agent caps.");
      nvAppendArrayElement(_entryAgents,agent);
      ArrayResize( _entryDecisions, ArraySize( _entryAgents ) );
      return;
    }
    if(caps==TRADE_AGENT_EXIT)
    {
      CHECK(agent.getCapabilities() & TRADE_AGENT_EXIT,"Invalid trading agent caps.");
      nvAppendArrayElement(_exitAgents,agent);
      ArrayResize( _exitDecisions, ArraySize( _exitAgents ) );
      return;
    }
    
    THROW("Unsupported agent caps: "<<(int)caps)
  }
  
  /*
  Function: getMarket
  
  Retrieve the market on which this currency trader is working currently:
  */
  nvMarket* getMarket()
  {
    // We return our current market depending on our current trader mode:
    return getManager().getMarket(_marketType);
  }
  
  /*
  Function: getPositionType
  
  Retrieve the current position type of this trader
  */
  PositionType getPositionType()
  {
    nvMarket* market = getMarket();
    return market.getPositionType(_symbol);  
  }

  /*
  Function: hasOpenPosition
  
  Method used to check if this currency trader currently has an open position on the market.
  */
  bool hasOpenPosition()
  {
    return getPositionType()!=POS_NONE;    
  }
  
  /*
  Function: removeTradingAgent
  
  Method called whend we need to remove a trading agent from this trader.
  */
  void removeTradingAgent(nvTradingAgent* agent)
  {
    CHECK(agent!=NULL,"Invalid trading agent.")
    nvRemoveArrayElement(_entryAgents,agent);
    nvRemoveArrayElement(_exitAgents,agent);
    ArrayResize( _entryDecisions, ArraySize( _entryAgents ) );
    ArrayResize( _exitDecisions, ArraySize( _exitAgents ) );
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
    if(val!=_weight) {
      _weight = val;

      // Also send the weight update message:
      nvBinStream msg;
      msg << (ushort)MSGTYPE_TRADER_WEIGHT_UPDATED;
      msg << getSymbol();
      msg << getManager().getCurrentTime();
      msg << val;
      getManager().sendData(msg);
    }
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
    // Retrieve the current time from the PortfolioManager:
    nvPortfolioManager* man = getManager();
    datetime ctime = man.getCurrentTime();

    // Now check if we are inside a position or not:
    if(hasOpenPosition())
    {
      // We are inside the market, so we check if we should exit from it:
      int num = ArraySize( _exitAgents );
      for(int i=0;i<num;++i)
      {
        _exitDecisions[i] = _exitAgents[i].getExitDecision(ctime);
      }

      // submit the agents point of views to the exit decision composer:
      double decision = _exitDecisionComposer.evaluate(_exitDecisions);

      if(getPositionType()==POS_LONG && decision<0.0)
      {
        // We should close the position.
        closePosition();
      }
      if(getPositionType()==POS_SHORT && decision>0.0)
      {
        // We should close the position.
        closePosition();
      }
    }
    else {
      // We are outside of the market, so we should check if we should enter it:
      int num = ArraySize( _entryAgents );
      for(int i=0;i<num;++i)
      {
        _entryDecisions[i] = _entryAgents[i].getEntryDecision(ctime);
      }

      // submit the agents point of views to the entry decision composer:
      double decision = _entryDecisionComposer.evaluate(_entryDecisions);

      openPosition(decision);

      if(decision>0.0)
      {
        // TODO: here we should enter a LONG position.

      }
      if(decision<0.0)
      {
        // TODO: here we should enter a SHORT position.
      }
    }

    logDEBUG(TimeLocal()<<": Updated CurrencyTrader.")
  }

  /*
  Function: computeEstimatedMaxLost
  
  This method is used to compute the estimated max lost that can be observed in the recent
  deal history. It will be used to determine what value should be used as a stop loss for
  the following deals.
  */
  double computeEstimatedMaxLost(double confidenceLevel)
  {
    // First we have to retrieve all the negative profits from the deal history:
    double negPoints[];
    int num = ArraySize( _previousDeals );
    double points;
    for(int i=0;i<num;++i)
    {
      points = -_previousDeals[i].getNumPoints();
      if(points>0.0)
      {
        nvAppendArrayElement(negPoints,points);
      }
    }

    num = ArraySize( negPoints );
    // logDEBUG("Computing estimated max lost with "<<num<<" samples.");

    // if we don't have enough samples then we just return an initialization value:
    if(num<TRADER_MIN_NUM_SAMPLES)
    {
      return TRADER_DEFAULT_LOST_POINTS;
    }

    // We assume we have enough values to build a bootstrap statistic:

    // We start with computing the mean:
    nvMeanBootstrap meanBoot;
    meanBoot.evaluate(negPoints);

    // We do not simply retrieve the mean, but instead we retrieve the highest value of the confidence interval 
    // given by the confidence level argument.

    double max_mean = meanBoot.getMaxValue(confidenceLevel);

    // Then we do the same for the standard error computation:
    nvStdDevBootstrap devBoot;
    devBoot.evaluate(negPoints);

    // And we retrieve the max value of the desired confidence interval:
    double max_dev = devBoot.getMaxValue(confidenceLevel);

    // And from that we can determine what would be our maximum number of lost points
    // (assuming a normal distribution, and forcing a confidence level of 95% for this
    // last step)
    // TODO: we should add support for computing the quantiles of the normal distribution
    // So that we should still use the provided confidence level argument for this last step.
    double max_lost = max_mean + 2*max_dev;
    // logDEBUG("Computed estimated max lost value of "<<max_lost<<" with confidence level "<< confidenceLevel);

    return max_lost;
  }
  
  /*
  Function: computeLotSize
  
  Method used to compute the lot size that should be used for the next trader that
  we want to open. It will use the risk manager to perform the actual computation:
  */
  double computeLotSize(double lostPoints, double confidence)
  {
    nvRiskManager* rman = getManager().getRiskManager();
    return rman.evaluateLotSize(getMarket(), _symbol, lostPoints, _weight, confidence);
  }
  
  /*
  Function: openPosition
  
  Method called to open a position with this trader given a confidence value
  */
  bool openPosition(double confidence)
  {
    if(confidence==0.0)
    {
      // nothing to do in that case.
      return false;
    }

    // Get the current estimation of the number of points that could be lost with a given
    // confidence level.
    // TODO: retrieve the desired confidence level from the risk manager itself ?
    double lostPoints = computeEstimatedMaxLost(0.95);

    // Estimate the lot size that we should used for this trade:
    double lotSize = computeLotSize(lostPoints,MathAbs(confidence));
    
    if(lotSize==0.0)
    {
      // nothing to open:
      return false;
    }

    // Retrieve the current market:
    nvMarket* market = getMarket();
    market.openPosition(_symbol, confidence>0.0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, lotSize, lostPoints );
    return true;
  }
  
  /*
  Function: closePosition
  
  Method called to close the current position on this symbol if any.
  */
  void closePosition()
  {
    nvMarket* market = getMarket();
    market.closePosition(_symbol);
  }
  
  /*
  Function: onDeal
  
  Method called each time a new deal owned by this trader is completed.
  */
  void onDeal(nvDeal* deal)
  {
    // Ensure this deal is valid:
    CHECK(deal!=NULL,"Invalid deal pointer.");
    CHECK(deal.getCurrencyTrader()==THIS,"Invalid deal trader "<<deal.getCurrencyTrader().getID());
    CHECK(deal.isDone(),"Received not done deal");
    CHECK(deal.getMarketType()==_marketType,"Mismatch in currency trader and deal market type.");
    
    // If this is a virtual deal, then we should ensure that the virtual balance gets updated properly.
    getMarket().acknowledgeDeal(deal);

    // Increment the deal count:
    _dealCount++;

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
    getManager().addProfitSample(deal.getNominalProfit(),deal.getTraderUtility());

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
        // delta = (double)(dtime - (lastTime==0 ? ptr.getEntryTime() : lastTime))/3600.0;
        // CHECK_RET(delta>0.0,0.0,"Detected invalid deal duration.");

        // Compute the duration of the deal in hours:
        delta = MathMax((double)(dtime - ptr.getEntryTime()),1.0)/3600.0;

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
    nvPortfolioManager* man = getManager();

    // We should consider only a fixed period of time in the past to perform the utility computation
    // this duration is retrieved from the portfolio manager itself,
    // as a number of seconds.
    int duration = man.getUtilityWindowSize();

    // We use the current server time as reference, and we compute the starting point of the window
    // from that:
    datetime stopTime = man.getCurrentTime();
    datetime startTime = stopTime-duration;

    // We now iterate in the deal history, and we compute the utility using only the deals that finished in that time
    // frame:
    _utility = computeProfitUtility(startTime,stopTime);

    // Send message to notify utility is updated:
    nvBinStream msg;
    msg << (ushort)MSGTYPE_TRADER_UTILITY_UPDATED;
    msg << getSymbol();
    msg << getManager().getCurrentTime();
    msg << _utility;
    
    getManager().sendData(msg);

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
