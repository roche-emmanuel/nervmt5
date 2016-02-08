// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/trading/PatternTrader.mqh>

void writeCSV(MqlRates &rates[], string sname,string period = "M1", string suffix="")
{
  string rpath = "Z:\\dev\\projects\\deepforex\\inputs\\mt5_2015_12\\";
  string filename = sname +"_" + period +".csv";
  
  int handle = FileOpen(filename, FILE_WRITE | FILE_ANSI);

  int len = ArraySize( rates );
  logDEBUG("Writing "<<len<<" samples for symbol " << sname);

  FileWriteString(handle,StringFormat("date,time,%s_open,%s_high,%s_low,%s_close,%s_volume\n",sname,sname,sname,sname,sname));

  MqlDateTime dts;
  string line;
  for(int i =0; i <len; i++)
  {
    TimeToStruct(rates[i].time,dts);
    line = StringFormat("%04d.%02d.%02d,%02d:%02d,%f,%f,%f,%f,0\n",
      dts.year,dts.mon,dts.day,dts.hour,dts.min,
      rates[i].open,rates[i].high,rates[i].low,rates[i].close);

    FileWriteString(handle,line);
  }

  FileFlush(handle);
  FileClose(handle);
}


void OnStart()
{
  nvLogManager* lm = nvLogManager::instance();
  string fname = "test_pattern_trader.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  logDEBUG("Initializing PatternTrader test");

  string filename = "EURUSD_tick_2015_01.csv";

  int handle = FileOpen(filename, FILE_READ | FILE_ANSI | FILE_TXT);
  // int numTicks = 30000+30+1+10+20;
  int numTicks = 60000+30+1+10+20;
  // int numTicks = 120000+30+1+10+20;
  string sep = ",";
  ushort u_sep = StringGetCharacter(sep,0);


  nvPatternTrader* trader = new nvPatternTrader("EURUSD",true,1);
  trader.setVariationLevel(20.0);
  // trader.setVariationLevel(15.0);

  double bid,ask;
  string line;
  string elems[];

  datetime startTime = TimeLocal();

  for(int i=0; i<numTicks; ++i)
  {
    line = FileReadString(handle);
    // logDEBUG("Read line: "<<line);

    int len = StringSplit(line,u_sep,elems); 
    CHECK(len==5,"Invalid number of elements!");

    // We only keep the time tag and the prediction:
    bid = StringToDouble(elems[1]);
    ask = StringToDouble(elems[2]);

    trader.addInput((bid+ask)*0.5);
    if(i%200==0)
    {
      logDEBUG("Done "<<StringFormat("%.2f%%",100.0*(double)i/(double)numTicks));
    }
  }

  datetime endTime = TimeLocal();

  RELEASE_PTR(trader);

  logDEBUG("Done executing PatternTrader test in "<<(int)(endTime-startTime)<<" seconds.");
}
