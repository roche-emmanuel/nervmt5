#include <nerv/core.mqh>

class nvCurrencyTrader;

enum AgentType
{
  TRADE_AGENT_UNKNOWN = 0,
  TRADE_AGENT_ICHIMOKU = 1,
};

enum AgentCapabilities
{
  TRADE_AGENT_ENTRY = 1,
  TRADE_AGENT_EXIT = 2,
  TRADE_AGENT_ENTRY_EXIT = 3,
};

/*
Class: nvTradingAgent

Class used as a base class to represent a trading agent in a given
currency trader.
*/
class nvTradingAgent : public nvObject
{
protected:
  // Agent type:
  AgentType _agentType;

  // Agent mode:
  AgentCapabilities _agentCapabilities;

  // Reference on parent trader:
  nvCurrencyTrader* _trader;

  // Keep a reference on the random generator to use:
  SimpleRNG* _rng;

  // The period used inside this agent:
  ENUM_TIMEFRAMES _period;

  // Symbol name:
  string _symbol;

  // Number of lag period that should be applied on this agent when computing its decision
  // given in number of periods.
  int _lag;

  // flag to specify if this agent is already initialized:
  bool _initialized;

  // Previous time this agent was updated:
  datetime _prevTime;

  // Previous time a bar was detected for this agent.
  datetime _prevBarTime;

public:
  /*
    Class constructor.
  */
  nvTradingAgent(nvCurrencyTrader* trader)
  {
    CHECK(trader,"Invalid parent trader.");

    _rng = trader.getManager().getRandomGenerator();

    // Default value for the agent type:
    _agentType = TRADE_AGENT_UNKNOWN;
    _agentCapabilities = (AgentCapabilities)0; // No support by default.
    _trader = trader;
    _symbol = _trader.getSymbol();
    _initialized = false;
    _lag = 0;
    _period = PERIOD_M1;
    _prevTime = 0;
    _prevBarTime = 0;
    
    randomizeLag(AGENT_MAX_LAG);
    randomizePeriod();
  }

  /*
    Copy constructor
  */
  nvTradingAgent(const nvTradingAgent& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvTradingAgent& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvTradingAgent()
  {
    // No op.
  }

  /*
  Function: getCapabilities
  
  Retrieve the capabilities of this agent.
  */
  AgentCapabilities getCapabilities()
  {
    return _agentCapabilities;
  }
  
  /*
  Function: getAgentType
  
  Retrieve the agent type
  */
  AgentType getAgentType()
  {
    return _agentType;
  }
  
  /*
  Function: getPeriod
  
  Retrieve the period used by this trader.
  */
  ENUM_TIMEFRAMES getPeriod()
  {
    return _period;
  }
  
  /*
  Function: setPeriod
  
  Set the period to use for this agent
  */
  void setPeriod(ENUM_TIMEFRAMES period)
  {
    _period = period;
  }
  
  /*
  Function: getLag
  
  Retrieve the current lag value for this agent
  */
  int getLag()
  {
    return _lag;
  }
  
  /*
  Function: setLag
  
  Assign the lag value for this trader in number of periods
  */
  void setLag(int lag)
  {
    _lag = lag;
  }
  
  /*
  Function: getEntryDecision
  
  Method called to retrieve the entry decision that this agent would take on its own.
  */
  virtual double getEntryDecision(datetime time)
  {
    if(!_initialized) {
      initialize();
      _initialized = true;
    }

    datetime rtime = time - _lag * nvGetPeriodDuration(_period);

    update(rtime);

    // return the computed value taking the lag into account:
    return computeEntryDecision(rtime);
  }

  /*
  Function: getExitDecision
  
  Method called to retrieve the exit decision that this agent would take on its own. 
  */
  double getExitDecision(datetime time)
  {
    if(!_initialized) {
      initialize();
      _initialized = true;
    }

    datetime rtime = time - _lag * nvGetPeriodDuration(_period);
    
    update(rtime);

    // return the computed value taking the lag into account:
    return computeExitDecision(rtime);
  }  

  /*
  Function: update
  
  Method used to update the state of the trader.
  */
  virtual void update(datetime time)
  {
    CHECK(time>=_prevTime,"Going back in time ?! "<<_prevTime<<" > "<<time);
    if(_prevTime==time) {
      // Nothing to update.
      return;
    }

    _prevTime = time;

    datetime New_Time[1];

    // copying the last bar time to the element New_Time[0]
    int copied=CopyTime(_symbol,_period,time,1,New_Time);
    CHECK(copied==1,"Invalid result for CopyTime operation: "<<copied);

    if(_prevBarTime!=New_Time[0]) // if old time isn't equal to new bar time
    {
      _prevBarTime=New_Time[0];            // saving bar time  
      handleBar();    
    }

    handleUpdate();
  }
  
  /*
  Function: handleBar
  
  Method used to handle the receiption of a new bar for the trader period.
  */
  virtual void handleBar()
  {
    // No op.
  }
  
  /*
  Function: handleUpdate
  
  Method used to handle the receiption of an update request
  */
  virtual void handleUpdate()
  {
    // No op.
  }
  
  /*
  Function: computeEntryDecision
  
  Method called to compute the entry decision taking into account the lag of this agent.
  This method should be reimplemented by derived classes that can provide entry decision.
  */
  virtual double computeEntryDecision(datetime time)
  {
    // TODO: Provide implementation
    THROW("No implementation");
    return 0.0;
  }
  
  /*
  Function: computeExitDecision
  
  Method called to compute the exit decision taking into account the lag of this agent.
  This method should be reimplemented by derived classes that can provide exit decision. 
  */
  virtual double computeExitDecision(datetime time)
  {
    // TODO: Provide implementation
    THROW("No implementation");
    return 0.0;
  }
  
  /*
  Function: randomizePeriod
  
  Method called to randomize the period value for this agent
  */
  void randomizePeriod(ENUM_TIMEFRAMES minPeriod = PERIOD_M1, ENUM_TIMEFRAMES maxPeriod = PERIOD_D1)
  {
    // We just need to generate a int in the provided range:
    int mini = nvGetPeriodIndex(minPeriod);
    int maxi = nvGetPeriodIndex(maxPeriod);
    _period = nvGetPeriodByIndex(_rng.GetInt(mini,maxi));
  }
  
  /*
  Function: randomizeLag
  
  Method called to randomize te value of the lag for this agent.
  Note that the lag will be computed as a iid N(0,(maxLag/3)^2) clamped
  to the range [0,maxLag]
  */
  void randomizeLag(int maxLag)
  {
    double val = _rng.GetNormal(0.0,maxLag/3.0);
    _lag = (int)MathFloor(nvClamp(val,0.0,(double)maxLag)+0.5);
  }
  
  /*
  Function: randomize
  
  Method called to randomize the values of the parameters for this agent.
  */
  virtual void randomize()
  {
    randomizeLag(AGENT_MAX_LAG);
    randomizePeriod();
  }
  
  /*
  Function: clone
  
  Method called to clone this agent
  */
  virtual nvTradingAgent* clone()
  {
    // We should not be able to clone this base class by default:
    return NULL;
  }
  
  /*
  Function: initialize
  
  Method called to initialize this trader on due time
  */
  virtual void initialize()
  {
    // No op.
  }
  
};
