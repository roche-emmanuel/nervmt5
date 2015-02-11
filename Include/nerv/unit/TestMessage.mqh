
#include <Object.mqh>

enum nvTestSeverity
{
  SEV_INFO,
  SEV_WARN,
  SEV_ERROR
};

class nvTestMessage : public CObject
{
public:
  string content;
  int severity;
  string filename;
  int lineNum;
  datetime time;
  
public:
  nvTestMessage() {};
  ~nvTestMessage() {};

};
