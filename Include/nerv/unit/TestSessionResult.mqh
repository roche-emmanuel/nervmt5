
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
    // This class should not delete the pointers on the suites!
    _suites.FreeMode(false);
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

  void writeTestResultData(string &data)
  {
    nvTestResult *result = (nvTestResult *)_testResults.GetFirstNode();
    string str, sname, name, status;
    double dur;
    int id = 0;
    bool first = true;
    while (result)
    {
      id++;
      sname = result.getParent().getName();
      name = result.getName();
      dur = result.getDuration();
      status = result.getStatus() == TEST_PASSED ? "PASSED" : "FAILED";

      // Now prepare the list of messages:
      CList *mlist = result.getMessages();
      string messages = "";
      if (mlist.Total() > 0)
      {
        nvTestMessage *m = (nvTestMessage *)mlist.GetFirstNode();
        string sev;
        while (m)
        {
          sev = m.getSeverity() == SEV_INFO ? "INFO" : m.getSeverity() == SEV_ERROR ? "ERROR" : "FATAL";
          messages += StringFormat("\n{content:\"%s\",severity:\"%s\",file:\"%s\",line:%d,time:\"%s\"},",
                                   m.getContent(), sev, m.getFilename(), m.getLineNumber(), (string)m.getDateTime());

          m = (nvTestMessage *)mlist.GetNextNode();
        }

        // Remove the last comma if applicable:
        int len = StringLen(messages);
        if (StringGetCharacter(messages, len - 1) == ',')
        {
          messages = StringSubstr(messages, 0, len - 1);
        }
      }

      str = StringFormat("%s{id:%d,sname:\"%s\",name:\"%s\",duration:%.3f,status:\"%s\",messages:[%s]},", first ? "" : "\n",
                         id, sname, name, dur, status, messages);

      first = false;
      data += str;

      result = (nvTestResult *)_testResults.GetNextNode();
    }

    // Remove the last comma if applicable:
    int len = StringLen(data);
    if (StringGetCharacter(data, len - 1) == ',')
    {
      data = StringSubstr(data, 0, len - 1);
    }
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
      content += FileReadString(src_handle) + "\n";
    }
    //--- close the file
    FileClose(src_handle);

    // Retrieve the current date:
    MqlDateTime date;
    TimeLocal(date);
    string datestr = StringFormat("%02d/%02d/%4d at %d:%02d:%02d", date.day, date.mon, date.year, date.hour, date.min, date.sec);
    int count = StringReplace(content, "${TEST_DATE}", datestr);

    //         {"id":1,"name":"name 1","description":"description 1","field3":"field3 1","field4":"field4 1","field5 ":"field5 1"},
    string tdata = "";
    writeTestResultData(tdata);
    count = StringReplace(content, "${TESTCASE_LIST}", tdata);
    // Count should be equal to 1.

    // Now write the complete content to the destination file:
    FileWriteString(handle, content);
  }
};
