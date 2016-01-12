// Include the core files:
#include <nerv/unit/Testing.mqh>
#include <nerv/core.mqh>
#include <nerv/utils.mqh>

void writeCSV(datetime& tags[], double& vals[], int stride, string fname)
{
  string filename = fname +".csv";
  
  int handle = FileOpen(filename, FILE_WRITE | FILE_ANSI);

  int len = ArraySize( tags );
  int nrows = len;
  logDEBUG("Writing "<<nrows<<" samples.");

  //  We don't write any header.
  // FileWriteString(handle,StringFormat("date,time,%s_open,%s_high,%s_low,%s_close,%s_volume\n",sname,sname,sname,sname,sname));

  string line;
  string msg;

  int idx = 0;

  for(int i =0; i <nrows; i++)
  {
    msg = (string)((int)tags[i]);

    for(int j=0;j<stride;++j) {
      msg += "," + DoubleToString(vals[idx++],5);
    }

    line = msg + "\n";

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
  int nsym = 7;
  string symbols[] = {"EURUSD","AUDUSD","GBPUSD","NZDUSD","USDCAD","USDCHF","USDJPY"};
  // int nsym = 7;
  // string symbols[] = {"EURUSD","EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD"};

  // datetime time = TimeLocal()-num*3600;
  datetime starttime = D'2015.12.01 00:00';
  // datetime starttime = D'2015.01.01 00:00';
  // datetime stoptime = D'2015.12.31 23:59';
  datetime stoptime = D'2016.01.09 00:00';

  double cvals[];
  datetime tags[];

  datetime time = starttime;
  datetime cur;
  double temp[];
  double val;
  datetime prevTime = 0;
  
  int count = 0;

  while(time <stoptime)
  {
    cur = time;
    if(nvGetValidSample(cur,temp,symbols))
    {
      if(prevTime< cur) {
        int len = ArraySize(temp);
        nvAppendArrayElement(tags,cur);
        for(int i=0;i<len;++i)
        {
          val = temp[i];
          nvAppendArrayElement(cvals,val);
        }
        count++;
        prevTime = cur;      
      }
    }
    time += 60;
  }

  logDEBUG("Read "<< count << " rows.")

  int stride = nsym+2;

  // Write the data to file: 
  writeCSV(tags,cvals,stride,"raw_inputs");

  logDEBUG("Done executing MultiDataRetriever.");
}
