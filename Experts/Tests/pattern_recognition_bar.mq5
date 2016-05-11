// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trading/PatternTrader.mqh>

void OnStart()
{
  nvLogManager* lm = nvLogManager::instance();
  string fname = "test_pattern_trader.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  logDEBUG("Initializing PatternTrader test");

  string filename = "EURUSD_M1_2014_2015.csv";

  int handle = FileOpen(filename, FILE_READ | FILE_ANSI | FILE_TXT);
  // int numTicks = 30000+30+1+10+20;
  // int numTicks = 60000+30+1+10+20;
  int numTicks = 400000+30+1+10+20;
  // int numTicks = 120000+30+1+10+20;
  string sep = ",";
  ushort u_sep = StringGetCharacter(sep,0);


  nvPatternTrader* trader = new nvPatternTrader("EURUSD",true,1);
  trader.setVariationLevel(30.0);
  // trader.setVariationLevel(20.0);
  // trader.setVariationLevel(15.0);
  
  // First we try with no spread at all:
  trader.setMeanSpread(0.0001);
  // trader.setGainTarget(0.00015);
  trader.setGainTarget(0.0001);

  trader.setPatternLength(40);
  trader.setPredictionOffset(5);
  trader.setPredictionLength(5);
  trader.setMaxPatternCount(50000);
  trader.setMinPatternCount(50000);

  double cprice;;
  string line;
  string elems[];

  datetime startTime = TimeLocal();

  for(int i=0; i<numTicks; ++i)
  {
    line = FileReadString(handle);
    // logDEBUG("Read line: "<<line);
    // format is: 2014.01.01,22:00,1.37553,1.37553,1.37552,1.37552,2

    int len = StringSplit(line,u_sep,elems); 
    CHECK(len==7,"Invalid number of elements: "<<len);

    // We only keep the time tag and the prediction:
    cprice = StringToDouble(elems[5]);

    // convert the time string to time value:
    // "2015.01.01 22:04:23.564"

    // logDEBUG("Substr 1 is: "<< StringSubstr(elems[0],0,16))
    
    datetime ctime = StringToTime(elems[0]+" "+elems[1]);
    // logDEBUG("Detected time: "<< ctime)

    trader.addInput(cprice,ctime);
    if(i%200==0)
    {
      logDEBUG("Done "<<StringFormat("%.2f%%",100.0*(double)i/(double)numTicks));
    }
  }

  datetime endTime = TimeLocal();

  RELEASE_PTR(trader);

  logDEBUG("Done executing PatternTrader test in "<<(int)(endTime-startTime)<<" seconds.");
}
