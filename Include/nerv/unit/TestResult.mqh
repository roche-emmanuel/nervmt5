
#include <Object.mqh>
#include <Arrays/List.mqh>
#include "TestMessage.mqh"

class nvTestSuite;

// Class used to encapsulate the results achieved
// during a test.
class nvTestResult : public CObject
{
protected:
  string _name;
  int _status;
  double _duration;
  nvTestSuite *_parent;
  CList _messages; // list of messages emitted during this test.

public:
  nvTestResult(const string &name, nvTestSuite* parent) : _name(name), _status(0), _duration(0.0), _parent(parent) {};

  ~nvTestResult() {};

  void setStatus(int status)
  {
    _status = status;
  }

  int getStatus() const
  {
    return _status;
  }

  void setDuration(double dur)
  {
    _duration = dur;
  }

  double getDuration() const 
  {
    return _duration;
  }

  nvTestSuite* getParent() const
  {
    return _parent;
  }

  string getName() const
  {
    return _name;
  }

  void addMessage(datetime time, int severity, const string &content, const string &filename, int lineNum)
  {
    nvTestMessage* msg = new nvTestMessage(time,severity,content,filename,lineNum);
    _messages.Add(msg);
  }

  CList* getMessages() const
  {
    return GetPointer(_messages);
  }
};
