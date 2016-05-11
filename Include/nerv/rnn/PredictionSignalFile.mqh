
#include <nerv/core.mqh>
#include <nerv/utils.mqh>
#include <nerv/rnn/PredictionSignal.mqh>

/*
Class: nvPredictionSignalFile

Class used to encapsulate a prediction signal from a given file
*/
class nvPredictionSignalFile : public nvPredictionSignal
{
protected:
  int _timetags[];
  double _predictions[];

public:
  /*
    Class constructor.
  */
  nvPredictionSignalFile(string filename, int minId = -1, int maxId = -1)
  {
    logDEBUG("Reading predictions from file: " << filename)
    int handle = FileOpen(filename,FILE_READ | FILE_CSV | FILE_ANSI);
    CHECK(handle != INVALID_HANDLE,"Could not open file " << filename << " for reading.");

    //--- read data from the file
    string line;
    string elems[];
    string sep = ",";
    ushort u_sep = StringGetCharacter(sep,0);
    int count = 0;

    // Read the first line which contains the headers:
    line = FileReadString(handle);
    logDEBUG("Headers: " << line)

    while (!FileIsEnding(handle))
    {
      //--- read the string
      line = FileReadString(handle);
      count++;
      // logDEBUG("Read line: "<<line);

      // Now split the string on ","
      // We should have 4 elements: timetag, eval_index, prediction, label
      int len = StringSplit(line,u_sep,elems); 
      CHECK(len==4,"Invalid number of elements!");

      // Check the id:
      int idx = (int)StringToInteger(elems[1]);

      if((minId==-1 || idx >= minId) && (maxId==-1 || idx <= maxId))
      {
        // We only keep the time tag and the prediction:
        int ival = (int)StringToInteger(elems[0]);
        nvAppendArrayElement(_timetags,ival);
        double dval = StringToDouble(elems[2]);
        nvAppendArrayElement(_predictions,dval);        
      }
    }
    
    //--- close the file
    FileClose(handle);

    logDEBUG("Read "<<count<< " samples.")
  }

  /*
    Copy constructor
  */
  nvPredictionSignalFile(const nvPredictionSignalFile& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvPredictionSignalFile& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvPredictionSignalFile()
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
    // Retrieve a prediction at a given timetag if any:
    int len = ArraySize( _timetags );

    for(int i=0;i<len;++i)
    {
      if(_timetags[i]==time)
      {
        return (_predictions[i]-0.5)*2.0;
      }
    }

    return 0.0;
  }
  
};
