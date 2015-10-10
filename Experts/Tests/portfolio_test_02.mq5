// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/expert/PortfolioManager.mqh>

void OnStart()
{
  nvLogManager* lm = nvLogManager::instance();
  string fname = "portfolio_test_02.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  logDEBUG("Initializing Portfolio test.");

  nvPortfolioManager man;

  // Add some currency traders:
  int nsym = 4;
  string symbols[] = {"GBPJPY", "EURUSD", "EURJPY", "USDCHF"};

  for(int j=0;j<nsym;++j)
  {
    nvCurrencyTrader* ct = man.addCurrencyTrader(symbols[j]);
    // We have to stay on the virtual market only for the moment:
    ct.setMarketType(MARKET_TYPE_VIRTUAL);
  }

  // Initial start time:
  datetime time = D'2015.01.01 00:00';

  int numDays = 31;
  int nsecs = 86400*numDays;
  for(int i=0;i<nsecs;++i) {
    man.update(time+i);
  }

  logDEBUG("Done executing portfolio test.");
}
