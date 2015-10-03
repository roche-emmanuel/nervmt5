#include <nerv/core.mqh>
#include <nerv/utils.mqh>
#include <nerv/math.mqh>
#include <nerv/enums.mqh>
#include <nerv/network/ZMQContext.mqh>
#include <nerv/network/ZMQSocket.mqh>
#include <nerv/network/BinStream.mqh>

// Maximum number of deals that can be stored in a CurrencyTrader:
#define TRADER_MAX_NUM_DEALS 1000

// Number of deals taken into account for the computation of the
// efficiency statistics:
#define EFFICIENCY_STATS_NUM_DEALS 300

// Max lag that should be acheivable by default on Trading agent with random generation:
#define AGENT_MAX_LAG 6

// Minimal number of samples used to built a statistic:
#define TRADER_MIN_NUM_SAMPLES 10

// Minimal deviation to consider for the utility statistics:
#define TRADER_MIN_UTILITY_DEVIATION 0.00001

// Default value for the currency trader lost points statistic,
// used until we have enough samples:
#define TRADER_DEFAULT_LOST_POINTS 50

#include <nerv/expert/RiskManager.mqh>
#include <nerv/expert/AgentFactory.mqh>
#include <nerv/expert/VirtualMarket.mqh>
#include <nerv/expert/RealMarket.mqh>
#include <nerv/expert/CurrencyTrader.mqh>
#include <nerv/expert/DecisionComposerFactory.mqh>
#include <nerv/expert/PriceManager.mqh>

/*
Class: nvPortfolioManager

This class represents the Portfolio manager of our expert implementation.
It is used as a singleton.
*/
class nvPortfolioManager : public nvObject
{

protected:
  // List of currency traders:
  nvCurrencyTrader* _traders[];

  // Value used to determine how efficient the Utility assignment should
  // be considered at a given time. When the value is high then "high"
  // utilities should be given an "high" weight relative to lower utilities.
  // when the value is low, then the difference in the weights should
  // be less obvious, and the utility assignment should be considered less
  // effective.
  double _utilityEfficiencyFactor;

  // ID to use for the magic ID of the next currency trader.
  // will be returned/incremented with the method getNewID()
  int _nextTraderID;

  // Should also contain a vector of all the previous utility values observed each time
  // a new deal is performed:
  double _dealUtilities[];

  // Should also contain a vector of all the previous nominal profit values observed each time
  // a new deal is performed:
  double _dealProfits[];

  // Instance of the risk manager for this portfolio:
  nvRiskManager _riskManager;

  // Instance of the Agent factory for this portfolio:
  nvAgentFactory _agentFactory;

  // Random generator for this portfolio:
  SimpleRNG _randomGenerator;

  // Virtual market instance used in the portfolio:
  nvVirtualMarket _virtualMarket;

  // Real market instance used in the portfolio:
  nvRealMarket _realMarket;

  // DecisionComposerFactory isntance for this portfolio:
  nvDecisionComposerFactory _decisionComposerFactory;

  // current server time:
  datetime _currentTime;

  // Price manager for this portfolio:
  nvPriceManager _priceManager;

  // Pointer on the ZMQ socket to use in this portfolio manager:
  nvZMQSocket* _socket;

public:
  /*
    Class constructor.
  */
  nvPortfolioManager(string endpoint="tcp://localhost:22223")
  {
    _socket = new nvZMQSocket(ZMQ_PUSH);
    
    // connect the socket:
    _socket.connect(endpoint);

    // Initiliaze state (and efficiency value):
    reset();

    // Assign this manager:
    _realMarket.setManager(THIS);
    _virtualMarket.setManager(THIS);
    _decisionComposerFactory.setManager(THIS);
    _riskManager.setManager(THIS);
    _priceManager.setManager(THIS);
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
    reset();

    RELEASE_PTR(_socket);
  }
  
  /*
  Function: getCurrencyTrader
  
  Iterate on the currency trader list to retrieve
  a specific trader by symbol:
  */
  nvCurrencyTrader* getCurrencyTrader(string symbol)
  {
    // Retrieve the current size of the list:
    int num = ArraySize( _traders );
    for(int i=0;i<num;++i)
    {
      if(_traders[i].getSymbol() == symbol)
      {
        return _traders[i];
      }
    }

    return NULL;
  }

  /*
  Function: getCurrencyTraderByID
  
  Retrieve a currency trader by its ID
  */
  nvCurrencyTrader* getCurrencyTraderByID(int id)
  {
    int num = ArraySize( _traders );
    for(int i=0;i<num;++i)
    {
      if(_traders[i].getID() == id)
      {
        return _traders[i];
      }
    }

    return NULL;
  }
  
  /*
  Function: addCurrencyTrader
  
  Method called to add a new currency trader with the given symbol.
  This call will return the newly created currency trader if successfull,
  and return NULL otherwise.
  */
  nvCurrencyTrader* addCurrencyTrader(string symbol)
  {
    // First we check if we already have a trader with the symbol:
    if(getCurrencyTrader(symbol))
    {
      logERROR("Trying to add already existing Currency Trader for symbol "<<symbol);
      return NULL;
    }

    // Check if the given symbol is valid:
    CHECK_RET(nvIsSymbolValid(symbol),NULL,"Invalid symbol.")
    
    // Create a new trader:
    nvCurrencyTrader* trader = new nvCurrencyTrader();
    trader.setSymbol(symbol);
    trader.setManager(THIS);
    
    int num = ArraySize( _traders );
    ArrayResize( _traders, num+1 );
    _traders[num] = trader;

    // Each time a new currency trader is created the weights should be
    // updated:
    updateWeights();
    
    return trader;
  }

  /*
  Function: removeCurrencyTrader
  
  Remove a currency trader by symbol
  */
  bool removeCurrencyTrader(string symbol)
  {
    int num = ArraySize( _traders );
    bool found = false;
    int i;
    for(i=0;i<num;++i)
    {
      if(_traders[i].getSymbol() == symbol)
      {
        // We should remove that trader from the list:
        RELEASE_PTR(_traders[i]);
        nvRemoveArrayItem(_traders,i);
        return true;
      }
    }

    return false;
  }
  
  /*
  Function: getNumCurrencyTraders
  
  Retrieve the number of currency traders available in this portfolio.
  */
  int getNumCurrencyTraders()
  {
    return ArraySize( _traders );
  }
  
  /*
  Function: removeAllCurrencyTraders
  
  Remove all the currency traders available in this portfolio.
  */
  void removeAllCurrencyTraders()
  {
    int num = ArraySize( _traders );
    for(int i=0;i<num;++i)
    {
      // We should remove that trader from the list:
      RELEASE_PTR(_traders[i]);
    }

    // Reset the content of the traders array:
    ArrayResize( _traders, 0 );    
  }
  
  /*
  Function: update
  
  Method called to update the complete state of this Portfolio Manager
  */
  void update()
  {
    logDEBUG(TimeLocal()<<": Updating Portfolio Manager.")
  }

  /*
  Function: addProfitSample
  
  Method called by the currency traders to notify the PortfolioManager that a new deal was performed,
  and thus that we have a new observation for th nominal profit and utility values.

  With this new sample the portfolio manager can update its efficiency statistics,
  and thus update the traders weights.
  */
  void addProfitSample(double nominalProfit, double utility)
  {
    nvAppendArrayElement(_dealUtilities,utility,EFFICIENCY_STATS_NUM_DEALS);

    nvAppendArrayElement(_dealProfits,nominalProfit,EFFICIENCY_STATS_NUM_DEALS);
    
    if(ArraySize(_dealUtilities)<2)
    {
      // Cannot update anything.
      return;
    }
    
    double dev = nvGetStdDevEstimate(_dealUtilities);
    double dev2 = nvGetStdDevEstimate(_dealProfits);

    // This is where we should update the utility efficiency factor:
    // if the deviation is zero, then we don't update anything:
    if(dev>0.0 && dev2>0.0)
    {
      // before updating the currency trader weights we should compute the
      // optimal efficiency factor here:
      updateUtilityEfficiencyFactor();
    }

    // updateWeights();
  }
  
  /*
  Function: getUtilityMean
  
  Retrieve the mean of the utility values over the recent previous deals.
  */
  double getUtilityMean()
  {
    return nvIsEmpty(_dealUtilities) ? 0.0 : nvGetMeanEstimate(_dealUtilities);
  }
  
  /*
  Function: getUtilityDeviation
  
  Retrieve the deviation of the utility valeus over the recent previous deals.
  */
  double getUtilityDeviation()
  {
    return ArraySize(_dealUtilities)<2 ? 0.0 : nvGetStdDevEstimate(_dealUtilities);
  }
  
  /*
  Function: updateWeights
  
  Method called each time the currency traders weights should
  be updated.
  */
  void updateWeights()
  {
    // Update the weights using the current utility efficiency factor:
    int num = getNumCurrencyTraders();
    if(num<=0)
    {
      // there is nothing to update here.
      return;
    }

    // Otherwise we need to compute the current weights using the 
    // current value of the utility of the traders:
    double exps[];
    ArrayResize( exps, num );

    // Retrieve the current mean of the utility values:
    double mu = getUtilityMean();

    // and also the current deviation:
    double dev = getUtilityDeviation();

    double alpha = _utilityEfficiencyFactor;
    double u;
    double denom = 0.0; // will contain the sum of all exp factors.
    for(int i=0;i<num;++i)
    {
      u = _traders[i].getUtility();
      exps[i] = dev>0.0 ? MathExp(alpha*(u-mu)/MathMax(dev,TRADER_MIN_UTILITY_DEVIATION)) : 1.0;
      denom += exps[i];
    }

    // Now assign each weight back to its corresponding trader:
    for(int i=0;i<num;++i)
    {
      _traders[i].setWeight(exps[i]/denom);
    }
  }

  /*
  Function: getNewID

  Method used to retrieve the next ID to use when creating a new
  currency trader.
  */
  int getNewID()
  {
   return _nextTraderID++;
  }

  /*
  Function: getUtilityEfficiency
  
  Retrieve the current utility efficiency:
  */
  double getUtilityEfficiency()
  {
    return _utilityEfficiencyFactor;
  }
  
  /*
  Function: getUtilities
  
  Retrieve the list of all current utilities from all traders.
  */
  void getUtilities(double &arr[])
  {
    int num = getNumCurrencyTraders();
    ArrayResize( arr, num );
    for(int i=0;i<num;++i)
    {
      arr[i] = _traders[i].getUtility();
    }
  }
  
  /*
  Function: getUtilityWindowSize
  
  Retrieve the period used for the utility computation of each currency trader.
  The value returned in is number of seconds.
  */
  int getUtilityWindowSize()
  {
    return 24*3600; // one day fixed for now.
  }
  
  /*
  Function: reset
  
  Method called to reset completed the state of this portfolio manager.
  This method will effectively delete all the currency traders created in this
  portfolio.
  */
  void reset()
  {

    removeAllCurrencyTraders();

    // Initialize the next Trader ID;
    _nextTraderID = 10000;

    // Reset current time:
    _currentTime = TimeCurrent(); // This should be overriden anyway.

    // Also reinitialize the current efficiency value:
    _utilityEfficiencyFactor = 1.0;

    // Reset the content of the dellUtilities and dealProfits vectors:
    ArrayResize(_dealUtilities, 0);
    ArrayResize(_dealProfits, 0);

    // Reset the state for the risk manager:
    _riskManager.setRiskLevel(0.02); // by default 2% of risk.

    // On reset we should also reset the random generated seeds:
    _randomGenerator.SetSeedFromSystemTime();

    // initialize the virtual balance:
    _virtualMarket.setBalance(3000.0);

    // Notify that a new portfolio is started:
    nvBinStream msg;
    msg << (ushort)MSGTYPE_PORTFOLIO_STARTED;
    sendData(msg);

  }

  /*
  Function: getRiskManager
  
  Retrieve the RiskManager component in this instance
  */
  nvRiskManager* getRiskManager()
  {
    return GetPointer(_riskManager);
  }
  
  /*
  Function: getPriceManager
  
  Retrieve the price manager instance.
  */
  nvPriceManager* getPriceManager()
  {
    return GetPointer(_priceManager);
  }
  
  /*
  Function: getAgentFactory
  
  Retrieve the AgentFactory compoentn in this instance
  */
  nvAgentFactory* getAgentFactory()
  {
    return GetPointer(_agentFactory);
  }
  
  /*
  Function: getDecisionComposerFactory
  
  Retrieve the DecisionComposerFactory in this instance
  */
  nvDecisionComposerFactory* getDecisionComposerFactory()
  {
    return GetPointer(_decisionComposerFactory);
  }
  
  /*
  Function: getRandomGenerator
  
  Retrieve the random generator associated with this portfolio manager
  */
  SimpleRNG* getRandomGenerator()
  {
    return GetPointer(_randomGenerator);
  }
  
  /*
  Function: getMarket
  
  Method used to retrieve the instance of the virtual or the real market in this portfolio
  */
  nvMarket* getMarket(MarketType mtype)
  {
    if(mtype==MARKET_TYPE_REAL)
      return GetPointer(_realMarket);
    else 
      return GetPointer(_virtualMarket);
  }
  
  /*
  Function: getCurrentTime
  
  Retrieve the current time of the trading system. This should be used
  instead of the provided MT5 server time to ensure that the portfolio manager
  controls the time of execution.
  */
  datetime getCurrentTime()
  {
    return _currentTime;
  }

  /*
  Function: setCurrentTime
  
  Method called to set the current time for the portfolio manager.
  Should only be called on a very high level.
  */
  void setCurrentTime(datetime ctime)
  {
    _currentTime = ctime;
  }
  
  
  /*
  Function: updateUtilityEfficiencyFactor
  
  Method called to update the value of the utilityEfficiencyFactor based
  on the previous performances on the utility weighting:
  */
  void updateUtilityEfficiencyFactor()
  {
    // To compute the efficiency factor we simple analyse the correlation between the
    // recent deal utilities and the corresponding nominalProfits.

    double corr = nvGetCorrelationEstimate(_dealUtilities,_dealProfits);

    // Notify if negative correlation is detected, since this would be quite abnormal:
    if(corr<0.0)
    {
      logWARN("Detected negative utility/profit correlation: "<<corr);
    }

    // Then we multiply this correlation value by a fixed value to ensure that 
    // we use the complete range of possibility for the weight differences:
    // And that should be our new efficiency factor:
    _utilityEfficiencyFactor = 2.0*corr;
  }  

  /*
  Function: sendData
  
  Method used to send data on the ZMQ socket connection
  */
  void sendData(const char &data[])
  {
    _socket.send(data);
  }

  /*
  Function: sendData
  
  Overloaded method to send data on the ZMQ socket connection
  */
  void sendData(string data)
  {
    char ch1[];
    StringToCharArray(data,ch1);
    sendData(ch1);
  }
  
  /*
  Function: sendData
  
  Overloaded method used to send BinStream objects.
  */
  void sendData(const nvBinStream& msg)
  {
    char data[];
    msg.getBuffer(data);
    sendData(data);
  }
  
  
};
