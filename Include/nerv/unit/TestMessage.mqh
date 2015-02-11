
#include <Object.mqh>

enum nvTestSeverity
{
  SEV_INFO,
  SEV_ERROR,
  SEV_FATAL
};

class nvTestMessage : public CObject
{
protected:
  string _content;
  int _severity;
  string _filename;
  int _lineNum;
  datetime _time;
  
public:
  nvTestMessage(datetime time, int severity, const string& content, const string& filename, int lineNum)
    : _content(content), _severity(severity), _filename(filename), _lineNum(lineNum), _time(time) {}

  ~nvTestMessage() {};

  string getContent() const
  {
    return _content;
  }

  int getSeverity() const
  {
    return _severity;
  }

  string getFilename() const
  {
    return _filename;
  }

  int getLineNumber() const
  {
    return _lineNum;
  }

  datetime getDateTime() const
  {
    return _time;
  }
};
