#include <nerv/core.mqh>
#include <nerv/network/Winsock.mqh>

WSAData_in g_wsaData;
bool g_initialized = false;

class nvSocket : public nvObject
{
public:
  nvSocket() {};
  ~nvSocket() {};

  virtual string toString() const
  {
    return "[nvSocket]";
  }

  /*
  Function: initialize
  
  Method called to perfor the winsock initialization.
  */
  static bool initialize()
  {
    if(g_initialized)
    {
      return true;
    }

    int retval = WSAStartup(0x202, g_wsaData.data); 
    if (retval != 0) { 
      logERROR("Server: WSAStartup() failed with error "<< retval); 
      uninitialize(); 
      return false; 
    } else {
      logDEBUG("Server: WSAStartup() is OK."); 
      g_initialized = true;
      return true;
    }
  }

  /*
  Function: uninitialize
  
  Method called to uninitialize the winsock library
  */
  static void uninitialize()
  {
    if(g_initialized) {
      WSACleanup();
      g_initialized = false;      
    }
  }
};
