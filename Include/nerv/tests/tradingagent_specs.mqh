
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/TradingAgent.mqh>

BEGIN_TEST_PACKAGE(tradingagent_specs)

BEGIN_TEST_SUITE("TradingAgent class")

BEGIN_TEST_CASE("should be able to create a TradingAgent instance")
	nvCurrencyTrader ct("EURUSD");
  nvTradingAgent agent(GetPointer(ct));
END_TEST_CASE()

BEGIN_TEST_CASE("Should be deleted properly by currency trader")
  nvCurrencyTrader* ct = new nvCurrencyTrader("EURUSD");

  nvTradingAgent* agent = new nvTradingAgent(ct);
  ct.addTradingAgent(agent);

  RELEASE_PTR(ct);
  ASSERT(!IS_VALID_POINTER(agent));
END_TEST_CASE()

BEGIN_TEST_CASE("Should be removable from currency trader")
  nvCurrencyTrader* ct = new nvCurrencyTrader("EURUSD");

  nvTradingAgent* agent = new nvTradingAgent(ct);
  ct.addTradingAgent(agent);

  ct.removeTradingAgent(agent);
  RELEASE_PTR(ct);

  ASSERT(IS_VALID_POINTER(agent));
  RELEASE_PTR(agent);
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide default agent type")
  nvCurrencyTrader ct("EURUSD");
  nvTradingAgent* agent = new nvTradingAgent(GetPointer(ct));

  ASSERT_EQUAL((int)agent.getAgentType(),(int)TRADE_AGENT_UNKNOWN);
  RELEASE_PTR(agent);
END_TEST_CASE()

BEGIN_TEST_CASE("Should throw if default decision methods are called")
  nvCurrencyTrader ct("EURUSD");
  nvTradingAgent agent(GetPointer(ct));

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

END_TEST_SUITE()

END_TEST_PACKAGE()
