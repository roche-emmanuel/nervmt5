
#include <nerv/unit/Testing.mqh>
#include <nerv/expert/CurrencyTrader.mqh>

BEGIN_TEST_PACKAGE(currencytrader_specs)

BEGIN_TEST_SUITE("CurrencyTrader class")

BEGIN_TEST_CASE("should be able to create a CurrencyTrader instance")
	nvCurrencyTrader ct;
	ct.setSymbol("EURUSD");
	ASSERT_EQUAL(ct.getSymbol(),"EURUSD");
END_TEST_CASE()

BEGIN_TEST_CASE("Should provide access to its utility value")
  nvCurrencyTrader ct;
  ct.setSymbol("EURUSD");
  // By default the utility value should be 0.0:
  ASSERT_EQUAL(ct.getUtility(),0.0);
END_TEST_CASE()

BEGIN_TEST_CASE("Should increment the unique ID properly")
  nvPortfolioManager man;
  nvCurrencyTrader ct;
  ct.setSymbol("EURUSD");
  ct.setManager(man);
  nvCurrencyTrader ct2;
  ct2.setSymbol("EURJPY");
  ct2.setManager(man);
  
  ASSERT_EQUAL(ct.getID(),10000);

  ASSERT_EQUAL(ct2.getID(),ct.getID()+1);
END_TEST_CASE()

BEGIN_TEST_CASE("Should compute its utility each time a deal is received")
  nvPortfolioManager man;

  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  
  // initial utility should be 0.0:
  ASSERT_EQUAL(ct.getUtility(),0.0);
  	
  // Now we generate a new deal:
  nvDeal* deal = new nvDeal();

	datetime time = TimeCurrent();
	deal.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
	deal.close(1.23457,time,10.0);
  deal.setMarketType(ct.getMarketType());

	// Send the deal to the CurrencyTrader:
	ct.onDeal(deal);

	// So, this is the first deal sent to the trader.
	// And there is only one trader, so its weight is always 1.0.
	// the new utility value should be:
	// profit = 10/2h = 5/h
	// dd = 0
	// u = mean_profit/(1+0) = 5.0
	ASSERT_EQUAL(ct.getUtility(),5.0);
	ASSERT_EQUAL(ct.getWeight(),1.0);
	
  // Reset the portfolio manager:
  man.reset();
END_TEST_CASE()

BEGIN_TEST_CASE("Should compute its utility with 2 traders")
  nvPortfolioManager man;

  nvCurrencyTrader* ct0 = man.addCurrencyTrader("EURUSD");
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURJPY");

	ASSERT(ct!=NULL);
	ASSERT(ct0!=NULL);

  // initial utility should be 0.0:
  ASSERT_EQUAL(ct.getUtility(),0.0);
  	
  // Now we generate a new deal:
  nvDeal* deal = new nvDeal();

	datetime time = TimeCurrent();
	deal.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*4,0.5);
	deal.close(1.23457,time-3600*2,10.0);
  deal.setMarketType(ct.getMarketType());

	// Send the deal to the CurrencyTrader:
	ct.onDeal(deal);

	// So, this is the first deal sent to the trader.
	// And there is only one trader, so its weight is always 1.0.
	// the new utility value should be:
	// profit = (10/2h) / lot = (10/2h)*2 = 10/h
	// dd = 0
	// u = mean_profit/(1+0) = 10.0
	ASSERT_EQUAL(ct.getUtility(),10.0);

	// The new weight should be:
	// dev if utility is zero, so the weight element should always be 1.0
	// double w = MathExp(10.0)/(MathExp(0.0)+MathExp(10));
	double w = 1.0/2.0;
	ASSERT_CLOSEDIFF(ct.getWeight(),w,1e-8);
	ASSERT_CLOSEDIFF(ct0.getWeight(),1.0-w,1e-8);
	
	deal = new nvDeal();

	deal.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
	deal.close(1.23457,time-3600,1.0);
  deal.setMarketType(ct.getMarketType());

	ct.onDeal(deal);

	// mean_profit = (10+1)/2
	// dd = 0
	// u = 5.5
	ASSERT_EQUAL(ct.getUtility(),5.5);
	double alpha = man.getUtilityEfficiency();
	double m = man.getUtilityMean();
	double dev = man.getUtilityDeviation();
	dev = dev==0.0 ? 1.0 : dev;
	w = MathExp(alpha*(5.5-m)/dev)/(MathExp(alpha*(0.0-m)/dev)+MathExp(alpha*(5.5-m)/dev));
	ASSERT_CLOSEDIFF(ct.getWeight(),w,1e-8);
	ASSERT_CLOSEDIFF(ct0.getWeight(),1.0-w,1e-8);

	deal = new nvDeal();

	deal.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600,2.0);
	deal.close(1.23457,time-1800,-4.0);
  deal.setMarketType(ct.getMarketType());

	ct.onDeal(deal);

	// nom_profit = -4 /2 /.5 = -4
	// mean_profit = (10+1-4)/3 = 7/3
	// dd = sqrt(4*4) = 4 
	// u = 3.5/(1.0+4)
	double u = (7.0/3.0)/(1.0+4);
	ASSERT_EQUAL(ct.getUtility(),u);
	alpha = man.getUtilityEfficiency();
	m = man.getUtilityMean();
	dev = man.getUtilityDeviation();
	dev = dev==0.0 ? 1.0 : dev;
	w = MathExp(alpha*(u-m)/dev)/(MathExp(alpha*(0.0-m)/dev)+MathExp(alpha*(u-m)/dev));
	ASSERT_CLOSEDIFF(ct.getWeight(),w,1e-8);
	ASSERT_CLOSEDIFF(ct0.getWeight(),1.0-w,1e-8);

  // Reset the portfolio manager:
  man.reset();
END_TEST_CASE()

BEGIN_TEST_CASE("Should release the deals it contains on deletion.")
  nvPortfolioManager man;

  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");

	datetime time = TimeCurrent();

  nvDeal* d1 = new nvDeal();
	d1.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*4,0.5);
	d1.close(1.23457,time-3600*2,10.0);
  d1.setMarketType(ct.getMarketType());
	ct.onDeal(d1);

	nvDeal* d2 = new nvDeal();
	d2.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
	d2.close(1.23457,time-3600,1.0);
  d2.setMarketType(ct.getMarketType());
	ct.onDeal(d2);

  man.reset();

  ASSERT(!IS_VALID_POINTER(d1));
	ASSERT(!IS_VALID_POINTER(d2));
END_TEST_CASE()

BEGIN_TEST_CASE("Should support collecting deals")
  
  nvPortfolioManager man;

  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");

	datetime time = TimeCurrent();

  nvDeal* d1 = new nvDeal();
	d1.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*4,0.5);
	d1.close(1.23457,time-3600*2,10.0);
  d1.setMarketType(ct.getMarketType());
	ct.onDeal(d1);

	nvDeal* d2 = new nvDeal();
	d2.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600*2,1.0);
	d2.close(1.23457,time-3600,1.0);
  d2.setMarketType(ct.getMarketType());
	ct.onDeal(d2);

	nvDeal* d3 = new nvDeal();
	d3.open(ct,ORDER_TYPE_BUY,1.23456,(int)time-3600,1.0);
	d3.close(1.23457,time-1800,1.0);
  d3.setMarketType(ct.getMarketType());
	ct.onDeal(d3);

	nvDeal* list[];
	ASSERT_EQUAL(ct.collectDeals(list,time-3600*3,time-1000),2);

	int num = ArraySize( list );
	ASSERT_EQUAL(num,2);
	ASSERT_EQUAL(d2,list[0]);
	ASSERT_EQUAL(d3,list[1]);

	// If we call the same method again the deals should be appended again:
	ASSERT_EQUAL(ct.collectDeals(list,time-3600*3,time-1000),2);
	num = ArraySize( list );
	ASSERT_EQUAL(num,4);
	
  man.reset();
END_TEST_CASE()

BEGIN_TEST_CASE("Should not have an open position by default.")
  nvPortfolioManager man;
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  ASSERT_EQUAL(ct.hasOpenPosition(),false);
  man.reset();
END_TEST_CASE()

BEGIN_TEST_CASE("Should be able to close a position")
  nvPortfolioManager man;
  nvCurrencyTrader* ct = man.addCurrencyTrader("EURUSD");
  ct.setMarketType(MARKET_TYPE_VIRTUAL);
  ct.openPosition(0.5);
  ASSERT_EQUAL(ct.hasOpenPosition(),true);
  int count = ct.getDealCount();
  ASSERT_EQUAL(count,0);
  
  ct.closePosition();
  ASSERT_EQUAL(ct.hasOpenPosition(),false);

	// Should have received one additional deal:
  ASSERT_EQUAL(ct.getDealCount(),count+1);
  
  man.reset();
END_TEST_CASE()

BEGIN_TEST_CASE("Should contain the proper buy deal informations")
  nvPortfolioManager man;
  string symbol = "GBPJPY";
  nvCurrencyTrader* ct = man.addCurrencyTrader(symbol);
  ct.setMarketType(MARKET_TYPE_VIRTUAL);

  // set the current portfolio time:
  datetime time = TimeLocal();
  man.setCurrentTime(time-60);
	  
  ct.openPosition(0.5);
  man.setCurrentTime(time);
  ct.closePosition();

  // There should be on deal performed:
  ASSERT_EQUAL(ct.getDealCount(),1);

  ASSERT_EQUAL(ct.getPreviousDealCount(),1);

  // Retrieve the previous deal:
  // Note that this method will behave as a time series retriever
  nvDeal* deal = ct.getPreviousDeal(0);

  ASSERT_EQUAL(deal.getEntryTime(),time-60);
  ASSERT_EQUAL(deal.getExitTime(),time);
  
  // Since the confidence was set to 0.5, this was a buy deal
  ASSERT_EQUAL(deal.getEntryPrice(),man.getPriceManager().getAskPrice(symbol,time-60));
  ASSERT_EQUAL(deal.getExitPrice(),man.getPriceManager().getBidPrice(symbol,time));
END_TEST_CASE()

BEGIN_TEST_CASE("Should contain the proper sell deal informations")
  nvPortfolioManager man;
  string symbol = "GBPJPY";
  nvCurrencyTrader* ct = man.addCurrencyTrader(symbol);
  ct.setMarketType(MARKET_TYPE_VIRTUAL);

  // set the current portfolio time:
  datetime time = TimeLocal();
  man.setCurrentTime(time-60);
	  
  ct.openPosition(-0.5);
  man.setCurrentTime(time);
  ct.closePosition();

  // There should be on deal performed:
  ASSERT_EQUAL(ct.getDealCount(),1);

  ASSERT_EQUAL(ct.getPreviousDealCount(),1);

  // Retrieve the previous deal:
  // Note that this method will behave as a time series retriever
  nvDeal* deal = ct.getPreviousDeal(0);

  ASSERT_EQUAL(deal.getEntryTime(),time-60);
  ASSERT_EQUAL(deal.getExitTime(),time);
  
  // Since the confidence was set to 0.5, this was a buy deal
  ASSERT_EQUAL(deal.getEntryPrice(),man.getPriceManager().getBidPrice(symbol,time-60));
  ASSERT_EQUAL(deal.getExitPrice(),man.getPriceManager().getAskPrice(symbol,time));
END_TEST_CASE()

BEGIN_TEST_CASE("Should support multiple deals")
  nvPortfolioManager man;
  string symbol = "GBPJPY";
  nvCurrencyTrader* ct = man.addCurrencyTrader(symbol);
  ct.setMarketType(MARKET_TYPE_VIRTUAL);
  SimpleRNG rng;
  rng.SetSeedFromSystemTime();
  
  int num = 30;
  // set the current portfolio time:
  datetime time = TimeLocal()-num*3600;

  int count = 0;

  for(int i = 0; i<num;++i)
  {
  	// Compute a random start/stop time (always in the 1 hour range)
  	int startOffset = rng.GetInt(0,3500);
  	int stopOffset = rng.GetInt(startOffset+1,3599);
  	
  	// Open the position:
  	man.setCurrentTime(time+startOffset);
  	if(ct.openPosition((rng.GetUniform()-0.5)*2.0))
  	{
  		count++;
  	};

  	man.setCurrentTime(time+stopOffset);
	  ct.closePosition();

	  time += 3600;
  }

  // There should be on deal performed:
  ASSERT_EQUAL(ct.getDealCount(),count);
  ASSERT_EQUAL(ct.getPreviousDealCount(),count);

  num = count;

  nvPriceManager* pman = man.getPriceManager();

  // Check the deal results:
  for(int i=0; i<num-1;++i)
  {
	  nvDeal* deal_new = ct.getPreviousDeal(i);
	  nvDeal* deal_old = ct.getPreviousDeal(i+1);

	  if(deal_new.getOrderType()==ORDER_TYPE_BUY)
	  {
		  ASSERT_EQUAL(deal_new.getEntryPrice(),pman.getAskPrice(symbol,deal_new.getEntryTime()));
		  ASSERT_EQUAL(deal_new.getExitPrice(),pman.getBidPrice(symbol,deal_new.getExitTime()));  
	  }
	  else
	  {
		  ASSERT_EQUAL(deal_new.getEntryPrice(),pman.getBidPrice(symbol,deal_new.getEntryTime()));
		  ASSERT_EQUAL(deal_new.getExitPrice(),pman.getAskPrice(symbol,deal_new.getExitTime()));  
	  }

	  // Ensure that the order of the deals is preserved:
	  ASSERT_LT(deal_old.getExitTime(),deal_new.getEntryTime());
  }

  // Since we have some deals we should also have utility statistics now:
  ASSERT(man.getUtilityMean()!=0.0);
  ASSERT_GT(man.getUtilityDeviation(),0.0);
END_TEST_CASE()


BEGIN_TEST_CASE("Should support multiple deals on multiple symbols")
  nvPortfolioManager man;

  int nsym = 4;
  string symbols[] = {"GBPJPY", "EURUSD", "EURJPY", "USDCHF"};

  for(int j=0;j<nsym;++j)
  {
  	nvCurrencyTrader* ct = man.addCurrencyTrader(symbols[j]);
  	ct.setMarketType(MARKET_TYPE_VIRTUAL);	
  }
  
  SimpleRNG rng;
  rng.SetSeedFromSystemTime();
  
  int num = 50;
  // set the current portfolio time:
  datetime time = TimeLocal()-num*3600;

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
	  		ASSERT_EQUAL(lotsize,0.0)
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
	  ASSERT_EQUAL(ct.getDealCount(),counts[j]);
	  ASSERT_EQUAL(ct.getPreviousDealCount(),counts[j]);  	

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
    logDEBUG("Computing estimated max lost with "<<num<<" samples.");

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

	    ASSERT_CLOSE(max_lost,ct.computeEstimatedMaxLost(confidenceLevel),0.1);
    }
  }

  // Since we have some deals we should also have utility statistics now:
  ASSERT(man.getUtilityMean()!=0.0);
  ASSERT_GT(man.getUtilityDeviation(),0.0);
END_TEST_CASE()

END_TEST_SUITE()

END_TEST_PACKAGE()
