#include <nerv/core.mqh>
#include <nerv/network/Winsock.mqh>

WSAData_stream g_wsaData;
bool g_initialized = false;

class nvSocket : public nvObject
{
protected:
  int _socket;

public:
  // constructor used to build a socket from an existing socket descriptor:
  nvSocket(int socket)
  {
    _socket = socket;
    CHECK(_socket!=INVALID_SOCKET,"Cannot build socket."); 

    // ulong iMode[1];
    // iMode[0]=1;

    // ioctlsocket(_socket,FIONBIO,iMode);
  }

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
    close();
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
  Function: close
  
  Close this socket
  */
  void close()
  {
    if(_socket!=INVALID_SOCKET)
    {
      CHECK(g_initialized,"Winsock not initialized.");

      // logDEBUG("Socket is: "<<_socket);
      int res = closesocket(_socket);
      CHECK(res==0,"Cannot close socket.")      
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
  
  /*
  Function: bind
  
  Method used to bind a server socket to a given port:
  */
  bool bind(ushort port)
  {
    sockaddr_in addrin;
    addrin.sin_family=AF_INET;
    addrin.sin_addr=INADDR_ANY;
    addrin.sin_port=htons(port);   

    // Convert to char array:
    sockaddr_in_stream ref=(sockaddr_in_stream)addrin;
    
    // Perform the connection:
    int res=bind(_socket, ref.data, sizeof(addrin));
    if(res!=0) {
      logERROR("Error in socket bind: " << WSAGetLastError());
      return false;
    }

    // connection established:
    return true;     
  }
  
  /*
  Function: listen
  
  Place this socket in listening mode
  */
  bool listen(int backlog)
  {
    int res=listen(_socket, backlog);
    if(res!=0) {
      logERROR("Error in socket listen: " << WSAGetLastError());
      return false;
    }

    // socket listening:
    return true;     
  }
  
  /*
  Function: accept
  
  Method used to accept an incoming connection
  */
  nvSocket* accept()
  {
    sockaddr_in_stream ref;
    int len[1];

    int socket = accept(_socket,ref.data,len);
    if(socket==INVALID_SOCKET)
      return NULL;

    logDEBUG("Detected valid client!");
    return new nvSocket(socket);
  }

  /*
  Function: send
  
  Method used to send some data other the socket connection
  */
  void send(string str)
  {
    char data[];
    StringToCharArray(str, data);
    send(data);
  }

  /*
  Function: send
  
  Method used to send a char array
  */
  void send(const char& data[]) 
  {
    int len = ArraySize( data );
    int res=send(_socket, data, len,0);
    if(res!=0) {
      logERROR("Error in socket send: " << WSAGetLastError());
      return false;
    }

    // socket listening:
    return true;         
  }
  
  
};
