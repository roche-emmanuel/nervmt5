
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

  // predictor communication socket:
  nvZMQSocket* _socket;
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

    _lastUpdateTime = 0;

    // Create the socket:
    _socket = new nvZMQSocket(ZMQ_PAIR);

    logDEBUG("Connecting socket to endpoint: " << endpoint)
    _socket.connect(endpoint);
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
      logDEBUG("Should send all the training data here.")
      //sendInputs(time, 2024);
    }
    else
    {
      logDEBUG("Should send only the latest bar data.");
      // If we are at time t, for instance t=12:11:00, this means
      // We are at the beginning of a new bar, and the previous bar is closed.
      // So we simply try to retrieve this "previous" bar, and we send it as
      // input feature to the predictor, if it is valid:
      datetime prevtime = time - 60;
      double cvals[];

      // retrieve the previous valid sample:
      if(getValidSample(prevtime,cvals))
      {
        sendInput(prevtime,cvals);
      }
    }

    _lastUpdateTime = time;
    
    return 0.0;
  }

  /*
  Function: sendInput
  
  Method used to send a single input sample
  */
  void sendInput(datetime timetag, double &features[])
  {
    // Build a string from this input:
    string msg = "single_input," + (string)((int)timetag);
    int len = ArraySize( features );
    for(int i=0;i<len;++i)
    {
      msg += "," + DoubleToString(features[i],5);
    }

    logDEBUG("Should send message: "<<msg)
    _socket.sendString(msg);
    logDEBUG("Message sent.")
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
    datetime timetag = 0;

    ArrayResize( cvals, nsym+2 );

    for(int i =0; i<nsym; ++i)
    {
      symbol = _inputs[i];
      MqlRates rates[];

      int len = CopyRates(symbol,PERIOD_M1,time,1,rates);
      while(len<0)
      {
        logDEBUG("Downloading data for "<<symbol<<"...")
        len = CopyRates(symbol,PERIOD_M1,time,1,rates);
        Sleep(50);
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
          logWARN("At " << time <<": detected mismatch in sample timetags: "<<timetag <<"!="<<rates[0].time);
          // We will not send that sample row:
          // but we anyway update the lastest available timetag:
          time = timetag;
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
      return false;
    }

    // Ensure that we are not on saturday, as this is not expected:
    CHECK_RET(dts.day_of_week!=6,false,"Unexpected day of week in timetag="<<timetag);

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

    return true;
  }

};
