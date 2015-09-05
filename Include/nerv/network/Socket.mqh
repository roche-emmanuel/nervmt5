#include <nerv/core.mqh>
#include <nerv/network/Winsock.mqh>

WSAData_stream g_wsaData;
bool g_initialized = false;

class nvSocket : public nvObject
{
protected:
  int _socket;

public:
  nvSocket() {
    // We assume that the initialize method is called first:
    _socket = INVALID_SOCKET;
    CHECK(g_initialized,"Winsock not initialized.");

    // logDEBUG("Creating real socket");
    _socket = socket(AF_INET , SOCK_STREAM , IPPROTO_IP);
    CHECK(_socket!=INVALID_SOCKET,"Cannot create socket.");      
    // logDEBUG("Initial socket is: "<<_socket);
  };

  ~nvSocket() {   
    // Close the socket:
    if(_socket!=INVALID_SOCKET)
    {
      CHECK(g_initialized,"Winsock not initialized.");

      // logDEBUG("Socket is: "<<_socket);
      int res = closesocket(_socket);
      CHECK(res==0,"Cannot close socket.")      
    }
  };

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

  /*
  Function: connect
  
  Method called to connect a socket
  */
  bool connect(string ip, ushort port)
  {
    //--- connecting the host after the socket initialization
    char ch[];
    StringToCharArray(ip, ch);
    
    //--- preparing the structure
    sockaddr_in addrin;
    addrin.sin_family=AF_INET;
    addrin.sin_addr=inet_addr(ch);
    addrin.sin_port=htons(port);

    // Convert to char array:
    sockaddr_in_stream ref=(sockaddr_in_stream)addrin;

    // Perform the connection:
    int res=connect(_socket, ref.data, sizeof(addrin));
    if(res!=0) {
      logERROR("Error in socket connection: " << WSAGetLastError());
      return false;
    }

    // connection established:
    return true;
  }
  
};
