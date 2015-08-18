#include <nerv/core.mqh>

class nvCurrencyTrader;

enum AgentType
{
  TRADE_AGENT_UNKNOWN = 0,
  TRADE_AGENT_ICHIMOKU = 1,
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

  // Reference on parent trader:
  nvCurrencyTrader* _trader;

  // The period used inside this agent:
  ENUM_TIMEFRAMES _period;

public:
  /*
    Class constructor.
  */
  nvTradingAgent(nvCurrencyTrader* trader)
  {
    CHECK(trader,"Invalid parent trader.");

    // Default value for the agent type:
    _agentType = TRADE_AGENT_UNKNOWN;
    _trader = trader;
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
  Function: getEntryDecision
  
  Method called to retrieve the entry decision that this agent would take on its own.
  This method should be reimplemented by derived classes that can provide entry decision.
  */
  virtual double getEntryDecision(datetime time)
  {
    // TODO: Provide implementation
    THROW("No implementation");
    return 0.0;
  }
  
  /*
  Function: getExitDecision
  
  Method called to retrieve the exit decision that this agent would take on its own.
  This method should be reimplemented by derived classes that can provide exit decision.  
  */
  virtual double getExitDecision(datetime time)
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
    int mini = (int)minPeriod;
    int maxi = (int)maxPeriod;
    _period = (ENUM_TIMEFRAMES)nvPortfolioManager::instance().getRandomGenerator().GetInt(mini,maxi);
  }
  
  /*
  Function: randomize
  
  Method called to randomize the values of the parameters for this agent.
  */
  virtual void randomize()
  {
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
