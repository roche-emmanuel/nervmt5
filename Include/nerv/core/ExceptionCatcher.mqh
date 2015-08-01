#include <nerv/core.mqh>

/*
Class: nvExceptionCatcher

This class is responsible for handling exceptions. When activated,
an exception will the thrown when receiving an exception message.
But it can also be disabled to ensure that during testing exceptions are
"catched" and would not stop the test program completely.
*/
class nvExceptionCatcher 
{
protected:
  bool _enabled;
  string _lastErrorMsg;
  int _errorCount;

protected:
  // Following methods are protected to respect the singleton pattern

  /*
    Class constructor.
  */
  nvExceptionCatcher()
  {
    _enabled = false;
    reset();
  }

  /*
    Copy constructor
  */
  nvExceptionCatcher(const nvExceptionCatcher& rhs)
  {
    this = rhs;
  }

  /*
    assignment operator
  */
  void operator=(const nvExceptionCatcher& rhs)
  {
    THROW("No copy assignment.")
  }

  /*
    Class destructor.
  */
  ~nvExceptionCatcher()
  {
    // No op.
  }

public:
  // Retrieve the instance of this class:
  static nvExceptionCatcher *instance()
  {
    static nvExceptionCatcher singleton;
    return GetPointer(singleton);
  }

  /*
  Function: isEnabled
  
  Method used to check if the exception catcher is enabled,
  in that case exceptions should normally not crash the program
  and simply generated an error message.
  */
  bool isEnabled()
  {
    return _enabled;
  }

  /*
  Function: setEnabled
  
  Enable of disable the exception catcher.
  */
  void setEnabled(bool val)
  {
    _enabled = val;
    if(_enabled)
    {
      reset(); // reset the counters in that case.
    }
  }
      
  /*
  Function: getLastError
  
  Retrieve the latest error message
  */
  string getLastError()
  {
    return _lastErrorMsg;
  }
  
  /*
  Function: reset
  
  Reset the error count and the last error message.
  */
  void reset()
  {
    _errorCount = 0;
    _lastErrorMsg = "";
  }

  /*
  Function: setLastError
  
  Assign a last error message and increment the error count
  */
  void setLastError(string msg)
  {
    if(msg!="")
    {
      logERROR("Exception occured: " << msg);
      _errorCount++;
      _lastErrorMsg = msg;
    }
  }
  
  /*
  Function: getErrorCount
  
  Retrieve the number of errors that occured since the
  last reset operation:
  */
  int getErrorCount()
  {
    return _errorCount;
  }
  
};
