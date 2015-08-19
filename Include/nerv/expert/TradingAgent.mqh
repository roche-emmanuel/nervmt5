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


  // Number of lag period that should be applied on this agent when computing its decision
  // given in number of periods.
  int _lag;

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
  Function: getLag
  
  Retrieve the current lag value for this agent
  */
  int getLag()
  {
    return _lag;
  }
  
  /*
  Function: getEntryDecision
  
  Method called to retrieve the entry decision that this agent would take on its own.
  */
  virtual double getEntryDecision(datetime time)
  {
    // return the computed value taking the lag into account:
    return computeEntryDecision(time - _lag * nvGetPeriodDuration(_period));
  }

  /*
  Function: getExitDecision
  
  Method called to retrieve the exit decision that this agent would take on its own. 
  */
  double getExitDecision(datetime time)
  {
    // return the computed value taking the lag into account:
    return computeExitDecision(time - _lag * nvGetPeriodDuration(_period));
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
  

};
