
#include <Object.mqh>
#include <Arrays/List.mqh>

class nvTestSuite;

class nvTestSessionResult : public CObject
{
protected:
  CList _suites; // Keep a reference on all suites.
  CList _testResults; // keep a reference on all test results.

public:
  nvTestSessionResult()
  {
    Print("Creating TestSessionResult.");
  };

  ~nvTestSessionResult()
  {
    Print("Deleting TestSessionResult.");
  };

  void addTestSuite(nvTestSuite *suite)
  {
    _suites.Add(suite);
  }

  void addTestResult(nvTestResult *result)
  {
    _testResults.Add(result);
  }

  void writeFile(int handle)
  {

    // Open the file containing the HTML code:
    ResetLastError();

    int src_handle = FileOpen("nvTestUI_template.html", FILE_READ | FILE_ANSI);
    string content = "";

    //--- read data from the file
    while (!FileIsEnding(src_handle))
    {
      //--- read the string
      content += FileReadString(src_handle) +"\n";
    }
    //--- close the file
    FileClose(src_handle);

    //         {"id":1,"name":"name 1","description":"description 1","field3":"field3 1","field4":"field4 1","field5 ":"field5 1"}, 

 
    // Now write the complete content to the destination file:
    FileWriteString(handle,content);
  }
};
