
#include "TestSuite.mqh"
#include <nerv/core.mqh>

#import "shell32.dll"
int ShellExecuteW(int hwnd,string Operation,string File,string Parameters,string Directory,int ShowCmd);
#import

// The Test manager root class, which is also a test suite itself.
class nvTestManager : public nvTestSuite
{
protected:
  string _targetLocation;

protected:
  // Protected constructor and destructor:
  nvTestManager() : nvTestSuite("Test session")
  {
    _targetLocation = "TestResults";
    
    logDEBUG("Creating TestManager.");
  };

  ~nvTestManager(void)
  {
    logDEBUG("Destroying TestManager.");
  };

public:
  // Retrieve the instance of this log manager:
  static nvTestManager *instance()
  {
    static nvTestManager singleton;
    return GetPointer(singleton);
  }

  void setTargetLocation(string loc)
  {
    _targetLocation = loc;

    nvLogManager* lm = nvLogManager::instance();
    string fname = _targetLocation + ".log";
    nvFileLogger* logger = new nvFileLogger(fname);
    lm.addSink(logger);
  }

  void run()
  {
    nvTestSessionResult sessionResult;
    int npass, nfail;
    run(GetPointer(sessionResult),npass,nfail);

    // At that point we can generate the human friendly result page from the Session result:
    displayResults(GetPointer(sessionResult));
    logDEBUG(TimeLocal()<<": all tests completed.")
  }

  void displayResults(nvTestSessionResult* results)
  {
    // Generate the output file:
    generateOutput(results);

    // Following calls were used to display an HTML report.
    // string terminal_data_path = TerminalInfoString(TERMINAL_DATA_PATH);
    // string file = terminal_data_path +"/MQL5/Files/"+_targetLocation+".html";
    // Print("Should open file: ", file);
    // shell32::ShellExecuteW(0,"open",file,"","",3);

    // Just display a web page for now:
    //Print("Opening web page...");
    //int res = shell32::ShellExecuteW(0,"open","http://www.google.fr","","",3);
    //Print("Web page opened with result: ",res);
  }

  void generateOutput(nvTestSessionResult* results)
  {
    results.writeReport();
  
    // The following calls where used to write an HTML report, but this proved
    // unhandy for handling numerous tests. Thus we only rely on text output above now.

    // string fname = _targetLocation+".html";
    // int handle = FileOpen(fname, FILE_WRITE|FILE_ANSI);
    
    // results.writeFile(handle);

    // FileClose(handle);
  }
};
