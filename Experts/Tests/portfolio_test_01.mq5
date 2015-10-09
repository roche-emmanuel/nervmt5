// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/expert/PortfolioManager.mqh>

void OnStart()
{
  nvLogManager* lm = nvLogManager::instance();
  string fname = "portfolio_test_01.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  logDEBUG("Initializing Portfolio test.");

  nvPortfolioManager man;

  // Initialize the symbols:
  int nsym = 4;
  string symbols[] = {"GBPJPY", "EURUSD", "EURJPY", "USDCHF"};

  for(int j=0;j<nsym;++j)
  {
  	nvCurrencyTrader* ct = man.addCurrencyTrader(symbols[j]);
  	ct.setMarketType(MARKET_TYPE_VIRTUAL);	
  }


  SimpleRNG rng;
  rng.SetSeedFromSystemTime();
  
  // Using 72 hours to ensure we get some deals.
  int num = 31*24;
  // set the current portfolio time:
  // datetime time = TimeLocal()-num*3600;
  datetime time = D'2015.01.01 00:00';

  int counts[];
  ArrayResize( counts, nsym );
  ArrayFill(counts , 0, nsym, 0);

  for(int i = 0; i<num;++i)
  {
  	for(int j=0;j<nsym;++j)
  	{	
	  	// Compute a random start/stop time (always in the 1 hour range)
	  	int startOffset = rng.GetInt(0,3500);
	  	int stopOffset = rng.GetInt(startOffset+1,3599);
	  	
	  	nvCurrencyTrader* ct = man.getCurrencyTrader(symbols[j]);

	  	// Open the position:
	  	man.setCurrentTime(time+startOffset);
	  	double confidence = (rng.GetUniform()-0.5)*2.0;

	  	bool res = ct.openPosition(confidence);

	  	if(res)
	  	{
	  		counts[j]++;
	  	}
	  	else
	  	{
	  		// Check that the lot size is 0.0:
	  		double lostPoints = ct.computeEstimatedMaxLost(0.95);
	  		double lotsize = ct.computeLotSize(lostPoints,MathAbs(confidence));
	  		// ASSERT_EQUAL(lotsize,0.0)
	  	}

	  	man.setCurrentTime(time+stopOffset);
		  ct.closePosition();
  	}

	  time += 3600;
  }

  // There should be on deal performed:
  for(int j=0;j<nsym;++j)
  {
  	nvCurrencyTrader* ct = man.getCurrencyTrader(symbols[j]);
	  // ASSERT_EQUAL(ct.getDealCount(),counts[j]);
	  // ASSERT_EQUAL(ct.getPreviousDealCount(),counts[j]);  	

	  // We can also compute the statistics for the max lost points, since we now have some deals:
	      // First we have to retrieve all the negative profits from the deal history:
    double negPoints[];
    num = counts[j];
    double points;
    for(int i=0;i<num;++i)
    {
      points = -ct.getPreviousDeal(i).getNumPoints();
      if(points>0.0)
      {
        nvAppendArrayElement(negPoints,points);
      }
    }

    num = ArraySize( negPoints );
    // logDEBUG("Computing estimated max lost with "<<num<<" samples.");

    // if we don't have enough samples then we just return an initialization value:
    if(num>TRADER_MIN_NUM_SAMPLES)
    {
    	double confidenceLevel = 0.95;

	    nvMeanBootstrap meanBoot;
	    meanBoot.evaluate(negPoints);
	    double max_mean = meanBoot.getMaxValue(confidenceLevel);

	    nvStdDevBootstrap devBoot;
	    devBoot.evaluate(negPoints);
	    double max_dev = devBoot.getMaxValue(confidenceLevel);
	
	    double max_lost = max_mean + 2*max_dev;

	    // ASSERT_CLOSE(max_lost,ct.computeEstimatedMaxLost(confidenceLevel),0.1);
    }
  }

  // int numDays = 31;
  // int nsecs = 86400*numDays;

  logDEBUG("Done executing portfolio test.");
}
