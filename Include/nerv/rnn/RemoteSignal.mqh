
#include <nerv/core.mqh>
#include <nerv/utils.mqh>
#include <nerv/rnn/PredictionSignal.mqh>
#include <nerv/network/ZMQContext.mqh>
#include <nerv/network/ZMQSocket.mqh>

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

  // Last timetag that was sent to the predictor:
  datetime _lastSentTimetag;

  // predictor communication socket:
  nvZMQSocket* _socket;

  // Seperator used for splitting strings:
  ushort _sep;

  // Number of training samples requested by the predictor.
  int _trainSize;

public:
  /*
    Class constructor.
  */
  nvRemoteSignal(string endpoint, string & inputs[])
  {
    logDEBUG("Creating remote signal with address: "<< endpoint)
    int len = ArraySize( inputs );
    for(int i=0;i<len;++i)
    {
      logDEBUG("Adding input symbol to remote signal: "<<inputs[i])
      nvAppendArrayElement(_inputs,inputs[i]);
    }

    string sep = ",";
    _sep = StringGetCharacter(sep,0);

    _trainSize = 0;
    _lastUpdateTime = 0;
    _lastSentTimetag = 0;

    // Create the socket:
    _socket = new nvZMQSocket(ZMQ_PAIR);

    logDEBUG("Connecting socket to endpoint: " << endpoint)
    _socket.connect(endpoint);

    // Just after connecting we should send the initialization data:
    // THe number of features is 2 + num input symbols:
    int nf = len + 2;
    string msg = "init," + (string)nf; 
    _socket.sendString(msg,0);

    string ans[];
    len = receiveData(ans);
    CHECK(ans[0]=="request_samples","Unexpected command id: "<<ans[0]);
    
    // Save the requested number of training samples for later initialization:
    _trainSize = (int)StringToInteger(ans[1]);
    logDEBUG("Received a request for "<< _trainSize <<" training samples.")
  }

  /*
  Function: receiveData
  
  Method used to receive some data in a string array:
  */
  int receiveData(string &data[], int flags = 0)
  {
    string ans = _socket.receiveString(flags);

    // Need to cut the string, we expect:
    // prediction,timetag,predvalue
    return StringSplit(ans,_sep,data);
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
    // destroy the socket:
    _socket.close();
    
    RELEASE_PTR(_socket);
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
      // logDEBUG("Should send all the requested training samples: " << _trainSize)
      // sendMultipleInputs(time-60, _trainSize);
    }

    _lastUpdateTime = time;

    logDEBUG("Should send only the latest bar data.");
    // If we are at time t, for instance t=12:11:00, this means
    // We are at the beginning of a new bar, and the previous bar is closed.
    // So we simply try to retrieve this "previous" bar, and we send it as
    // input feature to the predictor, if it is valid:
    datetime prevtime = time - 60;
    double cvals[];

    if(prevtime < 1448928000)
    {
      // discard this input for now.
      return 0.0;
    }

    // retrieve the previous valid sample:
    if(nvGetValidSample(prevtime,cvals,_inputs))
    {
      // Send the new input
      // and return the answer we get from the predictor:
      return sendInput(prevtime,cvals);
    }

    // Cannot make any prediction:
    return 0.0;
  }

  /*
  Function: sendInput
  
  Method used to send a single input sample
  This will also retrieve the latest prediction available
  */
  double sendInput(datetime timetag, double &features[])
  {
    // We should ensure here that we never go back in time
    if(_lastSentTimetag==timetag) 
    {
      // Not resending the last timetag:
      logWARN("Detected resending of single time tag at: "<<timetag)
      return 0.0;
    }

    CHECK_RET(_lastSentTimetag<timetag,0.0,"Trying to send old timetag: "<<timetag<<"<="<<_lastSentTimetag);
    
    // Update the last sent timetag:
    _lastSentTimetag = timetag;

    // Build a string from this input:
    string msg = "single_input," + (string)((int)timetag);
    int len = ArraySize( features );
    for(int i=0;i<len;++i)
    {
      msg += "," + DoubleToString(features[i],5);
    }

    // logDEBUG("Should send message: "<<msg)
    _socket.sendString(msg,0);
    // logDEBUG("Message sent.")

    // Read the prediction back from the predictor:
    string ans = _socket.receiveString(0);

    // Need to cut the string, we expect:
    // prediction,timetag,predvalue
    string elems[];
    len = StringSplit(ans,_sep,elems); 
    CHECK_RET(len==3,0.0,"Invalid number of elements: "<<len);
    CHECK_RET(elems[0]=="prediction",0.0,"Unexpected command id: "<<elems[0]);
    datetime dt = (datetime)StringToInteger(elems[1]);
    CHECK_RET(dt==timetag,0.0,"Mismatch in timetag: "<<dt <<"!="<<timetag);
    double pred = StringToDouble(elems[2]);
    logDEBUG("Received prediction value: "<<pred)
    return pred;
  }
  
  /*
  Function: getValidSample
  
  Method used to retrieve a valid simple at a given timetag,
  returns true if all the features are valid.
  */
  bool getValidSample(datetime& time, double &cvals[])
  {
    int nsym = ArraySize(_inputs);
    string symbol;
    datetime timetag = time;

    ArrayResize( cvals, nsym+2 );

    logDEBUG("Getting valid sample at time "<< (int)time)

    for(int i =0; i<nsym; ++i)
    {
      symbol = _inputs[i];
      MqlRates rates[];

      int len = CopyRates(symbol,PERIOD_M1,timetag,1,rates);
      while(len<0)
      {
        logDEBUG("Downloading data for "<<symbol<<"...")
        len = CopyRates(symbol,PERIOD_M1,timetag,1,rates);
        Sleep(10);
      }

      CHECK_RET(len==1,false,"Invalid result for CopyRates : "<<len)

      if(i==0) {
        // Initialize the timetag value:
        timetag = rates[0].time;
        logDEBUG("At "<<time<<": Writing previous bar timetag="<<timetag)
      }
      else {
        // Check if we still match the initial timetag, and if not, consider this as an
        // invalid sample:
        if(timetag!=rates[0].time) {
          logWARN("At " << time <<": detected mismatch in sample timetags: "<<timetag <<"!="<<rates[0].time<<" for symbol "<<symbol);
          // We will not send that sample row:
          // but we anyway update the lastest available timetag:
          time = MathMin(timetag,rates[0].time);
          return false;
        }
      }

      // Write the close price for this symbol:
      cvals[2+i] = rates[0].close;
    }

    // Update the current time value with the retrieved timetag:
    time = timetag;

    // If we reached this point it meansthe sample is correct,
    // Now we need to use the timetag to produce the weektime and the daytime:
    MqlDateTime dts;
    TimeToStruct(timetag,dts);

    // If we are on sunday, we don't send the data... because the weektime would be
    // out of range otherwise:
    if(dts.day_of_week==0) {
      logDEBUG("Discarding sample from sunday with timetag="<<timetag);
      // Apply an offset on the time to ensure we don't finish in a deadlock:
      // We want to get to the end of the previous friday;
      // So we need to remove the following number of seconds:
      int offset = 3600*24+dts.hour*3600+dts.min*60+dts.sec + 1; // + 1 to ensure we don't end on saturday!
      time -= offset;

      logDEBUG("Applying offset: "<<time)
      return false;
    }

    // Ensure that we are not on saturday, as this is not expected:
    CHECK_RET(dts.day_of_week!=6,false,"Unexpected day of week in timetag="<<timetag);

    // Now continue with the feature generation:
    double daylen = 24*60;
    double weeklen = 5*daylen;
    double daytime = dts.hour*60+dts.min;
    double weektime = (dts.day_of_week-1)*daylen + daytime;

    // note: we should not perform normalization ourself, this will be
    // done by the predictor:
    // normalize:
    // daytime /= daylen;
    // weektime /= weeklen;

    // Fill the feature buffer:
    cvals[0] = weektime;
    cvals[1] = daytime;

    return true;
  }

  /*
  Function: sendMultipleInputs
  
  Method used to send multiple inputs to the predictor
  */
  void sendMultipleInputs(datetime time, int num)
  {
    // We prepare arrays to hold the data:
    
    datetime timetags[];
    ArrayResize( timetags, num );

    // number of features:
    int nf = ArraySize( _inputs ) + 2;
    double cvals[];
    ArrayResize( cvals, nf*num );

    // Start with the immediate previous bar:
    datetime ctime = time-60;
    double temp[];
    MqlDateTime dts;
    int idx;

    for(int i=0;i<num;++i) {
      // try to get a valid samples:
      while(!nvGetValidSample(ctime,temp,_inputs)) {
        logDEBUG("Looking for valid sample at: "<<ctime)
        if((time-ctime) > (4*3600*24)) {
          logWARN("Detected too large gap in training data: discarding pre-training.");
          CHECK(false,"cannot train.")
          return;
        }
      }

      CHECK(ArraySize( temp )==nf,"Invalid number of features")

      // Ensure that the bar time still as sec = 0:
      TimeToStruct(ctime,dts);
      CHECK(dts.sec==0,"Invalid bar timetag: "<< ctime)

      // populate the arrays:
      timetags[num-1-i] = ctime;

      idx = nf*(num-1-i);
      for(int j=0;j<nf;++j)
      {
        cvals[idx+j] = temp[j];
      }

      // We have a valid sample for ctime,
      // the new iteration should be on ctime-60:
      ctime = ctime-60;
    }

    // We should now build a string from all those data:
    string msg = "multi_inputs," + (string)num + "," + (string)(nf+1);

    idx = 0;
    for(int i=0;i<num;++i)
    {
      msg += "," +(string)((int)timetags[i]);
      for(int j=0;j<nf;++j)
      {
        msg += ","+DoubleToString(cvals[idx++]);
      }
    }

    // Send the data:
    // logDEBUG("Should send message: "<<msg)
    _socket.sendString(msg,0);    
  }
  
};
