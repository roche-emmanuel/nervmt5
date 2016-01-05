
#include <nerv/core.mqh>
#include <nerv/utils.mqh>
#include <nerv/rnn/PredictionSignal.mqh>

/*
Class: nvRemoteSignal

Class used to encapsulate a prediction signal from a given file
*/
class nvRemoteSignal : public nvPredictionSignal
{
protected:
  // List of input symbol to use as inputs:
  string _inputs[];

  // last update time:
  datetime _lastUpdateTime;

public:
  /*
    Class constructor.
  */
  nvRemoteSignal(string address, string & inputs[])
  {
    logDEBUG("Creating remote signal with address: "<< address)
    int len = ArraySize( inputs );
    for(int i=0;i<len;++i)
    {
      logDEBUG("Adding input symbol to remote signal: "<<inputs[i])
      nvAppendArrayElement(_inputs,inputs[i]);
    }

    _lastUpdateTime = 0;

    logDEBUG("Should connect to address: " << address)
  }

  /*
    Copy constructor
  */
  nvRemoteSignal(const nvRemoteSignal& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvRemoteSignal& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvRemoteSignal()
  {
    // No op.
  }

  /*
  Function: getPrediction
  
  Return a prediction in the range (-1,1) or 0 if we are not 
  predicting anything for the requested date:
  */
  virtual double getPrediction(datetime time)
  {
    CHECK_RET(time>_lastUpdateTime,0.0,"Invalid last update time");

    // Before requesting a prediction we should update the reference time:
    if(_lastUpdateTime==0)
    {
      // This is the first initialization so we send all the training data
      logDEBUG("Should send all the training data here.")
      sendInputs(time, 2024);
    }
    else
    {
      logDEBUG("Should send only the latest bar data.");
      // If we are at time t, for instance t=12:11:00, this means
      // We are at the beginning of a new bar, and the previous bar is closed.
      // So we simply try to retrieve this "previous" bar, and we send it as
      // input feature to the predictor, if it is valid:
      sendPrevInputs(time);
    }

    _lastUpdateTime = time;
    
    return 0.0;
  }

  /*
  Function: getValidSample
  
  Method used to send the previous bar for a given timetag,
  if all the features are valid:
  */
  void getValidSample(datetime time)
  {
    int nsym = ArraySize(_inputs);
    string symbol;
    datetime timetag = 0;
    double cvals[];

    ArrayResize( cvals, nsym+2 );

    for(int i =0; i<nsym; ++i)
    {
      symbol = _inputs[i];
      MqlRates rates[];

      int len = CopyRates(symbol,PERIOD_M1,1,time,rates);
      while(len<0)
      {
        logDEBUG("Downloading data for "<<symbol<<"...")
        len = CopyRates(symbol,PERIOD_M1,1,time,rates);
        Sleep(50);
      }

      CHECK(len==1,"Invalid result for CopyRates : "<<len)

      if(i==0) {
        // Initialize the timetag value:
        timetag = rates[0].time;
        logDEBUG("At "<<time<<": Writing previous bar timetag="<<timetag)
      }
      else {
        // Check if we still match the initial timetag, and if not, consider this as an
        // invalid sample:
        if(timetag!=rates[0].time) {
          logWARN("At " << time <<": detected mismatch in sample timetags: "<<timetag <<"!="<<rates[0].time);
          // We will not send that sample row:
          return;
        }
      }

      // Write the close price for this symbol:
      cvals[2+i] = rates[0].close;
    }

    // If we reached this point it meansthe sample is correct,
    // Now we need to use the timetag to produce the weektime and the daytime:
    MqlDateTime dts;
    TimeToStruct(timetag,dts);

    // If we are on sunday, we don't send the data... because the weektime would be
    // out of range otherwise:
    if(dts.day_of_week==0) {
      logDEBUG("Discarding sample from sunday with timetag="<<timetag);
      return;
    }

    // Ensure that we are not on saturday, as this is not expected:
    CHECK(dts.day_of_week!=6,"Unexpected day of week in timetag="<<timetag);

    // Now continue with the feature generation:
    double daylen = 24*60;
    double weeklen = 5*daylen;
    double daytime = dts.hour*60+dts.min;
    double weektime = (dts.day_of_week-1)*daylen + daytime;

    // normalize:
    daytime /= daylen;
    weektime /= weeklen;

    // Fill the feature buffer:
    cvals[0] = weektime;
    cvals[1] = daytime;
  }
  
  /*
  Function: getValidSample
  
  Method used to retrieve a valid sample
  */
  bool getValidSample(datetime& time, string &symbols[], double &features[])
  {
    bool valid = false;
    while(!valid)
    {
      time -= 60;
      valid = getSample(time,symbols,features);
      if(time<_lastUpdateTime)
        return false;
    }

    return true;
  }
  
  /*
  Function: sendInputs
  
  Method used to send a given number of inputs
  */
  void sendInputs(datetime ctime, int num)
  {
    int nsym = ArraySize( _inputs );
    int nf = nsym+2;

    // for each symbol we need to collect num values,
    // And we also add the weektime and the daytime
    // So the total size we need is num*(nsym + 2):
    double cvals[];
    ArrayResize( cvals, nf*num );

    // And we have one time tag per row:
    datetime tvals[];
    ArrayResize( tvals, num );

    // For each row, we need to "find common" timetag
    // where all the symbols are available,
    // So we look for each row one by one, and we fill the final data array
    // in reverse order:
    double temp[];

    int ridx = num;
    int idx;
    bool valid;
    while(ridx>0)
    {
      // Read the start index for the row:
      idx = (ridx-1)*nf;

      // Retrieve the previous input:
      valid = false;
      while(!valid)
      {
        time -= 60;
        valid = getSample(time,_inputs,temp);
      }

      // Copy the data:
      for(int i=0;i<nf;++i)
      {
        cvals[idx+i] = temp[i];
      }

      tvals[ridx-1] = (int)time;
      
      // decrement the row ID:
      ridx--;
    }

    string symbol;
    for(int i =0; i<nsym; ++i)
    {
      symbol = _inputs[i];
      MqlRates rates[];
      int len = CopyRates(symbol,PERIOD_M1,1,num,rates);
      while(len<0)
      {
        logDEBUG("Downloading data for "<<symbol<<"...")
        len = CopyRates(symbol,PERIOD_M1,1,num,rates);
        Sleep(200);
      }

      CHECK(len==num,"Invalid result for CopyRates : "<<len)
      int idx = i;

      for(int j=0;j<len;++j)
      {
        cvals[idx] = rates[j].close;

      }
    }
  }
  
  /*
  Function: sendInputs
  
  Method used to send the inputs to a remote predictor.
  Does nothing by default:
  */
  void sendInputs(int &timetags[], double &features[])
  {
    
  }

};
