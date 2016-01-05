// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>

void writeCSV(MqlRates &rates[], string sname,string suffix="")
{
  string rpath = "Z:\\dev\\projects\\deepforex\\inputs\\mt5_2015_12\\";
  string filename = sname +"_M1.csv";
  
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
  string fname = "data_retriever.log";
  nvFileLogger* logger = new nvFileLogger(fname);
  lm.addSink(logger);

  logDEBUG("Initializing DataRetriever");

  // The symbols we need are:
  // "EURUSD","AUDUSD","GBPUSD","NZDUSD","USDCAD","USDCHF","USDJPY"
  // Initialize the symbols:
  // int nsym = 7;
  // string symbols[] = {"EURUSD","AUDUSD","GBPUSD","NZDUSD","USDCAD","USDCHF","USDJPY"};
  int nsym = 7;
  string symbols[] = {"EURUSD","EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD"};

  // datetime time = TimeLocal()-num*3600;
  datetime starttime = D'2015.12.01 00:00';
  datetime stoptime = D'2015.12.31 23:59';

  for(int i=0;i<nsym;++i)
  {
    logDEBUG("Selecting symbol " << symbols[i])
    SymbolSelect(symbols[i],true);

    // Read the rate data:
    MqlRates rates[];
    // logDEBUG("Copying rates")
    int len = CopyRates(symbols[i],PERIOD_M1,starttime,stoptime,rates);
    while(len<0)
    {
      logDEBUG("Downloading data for "<<symbols[i])
      len = CopyRates(symbols[i],PERIOD_M1,starttime,stoptime,rates);
      Sleep(200);
    }

    CHECK(len>0,"Invalid result for CopyRates")
    logDEBUG("Read "<<len<<" values for "<<symbols[i])

    // Write the data to file: 
    writeCSV(rates,symbols[i]);
  }

  logDEBUG("Done executing DataRetriever.");
}
