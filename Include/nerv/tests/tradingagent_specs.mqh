
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/TradingAgent.mqh>
#include <nerv/expert/agent/IchimokuAgent.mqh>

BEGIN_TEST_PACKAGE(tradingagent_specs)

BEGIN_TEST_SUITE("TradingAgent class")

BEGIN_TEST_CASE("should be able to create a TradingAgent instance")
	nvPortfolioManager man;
	nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
	
  nvTradingAgent agent(GetPointer(ct));
END_TEST_CASE()

BEGIN_TEST_CASE("Should be deleted properly by currency trader")
	nvPortfolioManager man;

  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");

  nvTradingAgent* agent = new nvTradingAgent(ct);
  
  // Should throw an error because this agent has no entry support:
  // BEGIN_ASSERT_ERROR("Unsupported agent caps:")
  ct.addTradingAgent(agent);
  // END_ASSERT_ERROR();

  man.reset();
  
  // TODO: add the test with a valid agent here.
  RELEASE_PTR(agent);
  // ASSERT(!IS_VALID_POINTER(agent));
END_TEST_CASE()

BEGIN_TEST_CASE("Should be removable from currency trader")
  nvPortfolioManager man;
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");

  nvTradingAgent* agent = new nvTradingAgent(ct);
  
  // BEGIN_ASSERT_ERROR("Unsupported agent caps:")
  ct.addTradingAgent(agent);
  // END_ASSERT_ERROR();

  // TODO: add the test with a valid agent here.
  
  ct.removeTradingAgent(agent);
  man.reset();

  ASSERT(IS_VALID_POINTER(agent));
  RELEASE_PTR(agent);
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide default agent type")
  nvPortfolioManager man;
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  nvTradingAgent* agent = new nvTradingAgent(ct);

  ASSERT_EQUAL((int)agent.getAgentType(),(int)TRADE_AGENT_UNKNOWN);
  RELEASE_PTR(agent);
END_TEST_CASE()

BEGIN_TEST_CASE("Should throw if default decision methods are called")
  nvPortfolioManager man;
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  nvTradingAgent agent(ct);

  ENUM_TIMEFRAMES period = agent.getPeriod();

  // Check that the period is value:
  ASSERT_GE((int)period,(int)PERIOD_M1);
  ASSERT_LE((int)period,(int)PERIOD_D1);
  // logDEBUG("Period is: "<<EnumToString(period));
  
  datetime time = TimeCurrent();
  BEGIN_ASSERT_ERROR("No implementation")
    agent.getEntryDecision(time);
  END_ASSERT_ERROR();

  BEGIN_ASSERT_ERROR("No implementation")
    agent.getExitDecision(time);
  END_ASSERT_ERROR();
  
END_TEST_CASE()

BEGIN_TEST_CASE("Should throw if default decision methods are called")
  nvPortfolioManager man;
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  nvTradingAgent agent(ct);

  ENUM_TIMEFRAMES period = agent.getPeriod();

  // Check that the period is value:
  ASSERT_GE((int)period,(int)PERIOD_M1);
  ASSERT_LE((int)period,(int)PERIOD_D1);
  // logDEBUG("Period is: "<<EnumToString(period));
  
  datetime time = TimeCurrent();
  BEGIN_ASSERT_ERROR("No implementation")
    agent.getEntryDecision(time);
  END_ASSERT_ERROR();

  BEGIN_ASSERT_ERROR("No implementation")
    agent.getExitDecision(time);
  END_ASSERT_ERROR();
  
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to create an ichimoku agent")
  nvPortfolioManager man;
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  nvIchimokuAgent agent(ct);
    
  // We should be able to add this agent without issue to the trader:
  ct.addTradingAgent(GetPointer(agent));

  ASSERT_EQUAL((int)agent.getAgentType(),(int)TRADE_AGENT_ICHIMOKU);

  // Then we should be able to remove this agent:
  ct.removeTradingAgent(GetPointer(agent));
END_TEST_CASE()


END_TEST_SUITE()

END_TEST_PACKAGE()
