#include <nerv/core.mqh>

// Bindings for winsock direct usage:

#import "ws2_32.dll"
int WSAStartup(int cmd, char &wsadata[]); 
int WSACleanup(); 
int WSAGetLastError(); 
int socket(int domaint,int type,int protocol); 
int closesocket(int socket); 
ushort htons(ushort hostshort);
ulong inet_addr(char &cp[]);
int connect(int socket, char& address[], int address_len); 

int bind(int socket, char& address[], int address_len); 
int listen(int socket, int backlog); 
int accept(int socket, char& address[], int& address_len[]); 
int send(int socket, char& buffer[], int length, int flags); 
// int recv(int socket, int& buffer[], int length, int flags); 
// int recvfrom(int socket, int& buffer[], int length, int flags, int& address[], int& address_len[]); 
// int sendto(int socket, int& message[], int length, int flags, int& dest_addr[], int dest_len); 
// int gethostbyname(string name); 
// int gethostbyaddr(string addr, int len, int type); 
// string inet_ntoa(int addr ); 
#import

//Addresses 
#define INADDR_ANY         0x00000000 
#define INADDR_LOOPBACK    0x7f000001 
#define INADDR_BROADCAST   0xffffffff 
#define INADDR_NONE        0xffffffff 

//ERRORS 
//socket fucntions errors 
#define INVALID_SOCKET             0 
#define SOCKET_ERROR               -1 
//WSAGatLastError() errors 
// Windows Sockets definitions of regular Microsoft C error constants 
#define WSAEINTR                   10004 
#define WSAEBADF                   10009 
#define WSAEACCES                  10013 
#define WSAEFAULT                  10014 
#define WSAEINVAL                  10022 
#define WSAEMFILE                  10024 
// Windows Sockets definitions of regular Berkeley error constants 
#define WSAEWOULDBLOCK             10035 
#define WSAEINPROGRESS             10036 
#define WSAEALREADY                10037 
#define WSAENOTSOCK                10038 
#define WSAEDESTADDRREQ            10039 
#define WSAEMSGSIZE                10040 
#define WSAEPROTOTYPE              10041 
#define WSAENOPROTOOPT             10042 
#define WSAEPROTONOSUPPORT         10043 
#define WSAESOCKTNOSUPPORT         10044 
#define WSAEOPNOTSUPP              10045 
#define WSAEPFNOSUPPORT            10046 
#define WSAEAFNOSUPPORT            10047 
#define WSAEADDRINUSE              10048 
#define WSAEADDRNOTAVAIL           10049 
#define WSAENETDOWN                10050 
#define WSAENETUNREACH             10051 
#define WSAENETRESET               10052 
#define WSAECONNABORTED            10053 
#define WSAECONNRESET              10054 
#define WSAENOBUFS                 10055 
#define WSAEISCONN                 10056 
#define WSAENOTCONN                10057 
#define WSAESHUTDOWN               10058 
#define WSAETOOMANYREFS            10059 
#define WSAETIMEDOUT               10060 
#define WSAECONNREFUSED            10061 
#define WSAELOOP                   10062 
#define WSAENAMETOOLONG            10063 
#define WSAEHOSTDOWN               10064 
#define WSAEHOSTUNREACH            10065 
#define WSAENOTEMPTY               10066 
#define WSAEPROCLIM                10067 
#define WSAEUSERS                  10068 
#define WSAEDQUOT                  10069 
#define WSAESTALE                  10070 
#define WSAEREMOTE                 10071 
#define WSAEDISCON                 10101 
// Extended Windows Sockets error constant definitions 
#define WSASYSNOTREADY             10091 
#define WSAVERNOTSUPPORTED         10092 
#define WSANOTINITIALISED          10093 
#define WSAENOMORE                 10102 
#define WSAECANCELLED              10103 
#define WSAEINVALIDPROCTABLE       10104 
#define WSAEINVALIDPROVIDER        10105 
#define WSAEPROVIDERFAILEDINIT     10106 
#define WSASYSCALLFAILURE          10107 
#define WSASERVICE_NOT_FOUND       10108 
#define WSATYPE_NOT_FOUND          10109 
#define WSA_E_NO_MORE              10110 
#define WSA_E_CANCELLED            10111 
#define WSAEREFUSED                10112 
// Authoritative Answer: Host not found 
#define WSAHOST_NOT_FOUND          11001 
// Non-Authoritative: Host not found, or SERVERFAIL 
#define WSATRY_AGAIN               11002 
// Non recoverable errors, FORMERR, REFUSED, NOTIMP 
#define WSANO_RECOVERY             11003 
// Valid name, no data record of requested type 
#define WSANO_DATA                 11004 
// no address, look for MX record 
#define WSANO_ADDRESS              11004 

//Adress Families 
#define AF_UNSPEC                  0 
#define AF_UNIX                    1 
#define AF_INET                    2 
#define AF_IMPLINK                 3 
#define AF_PUP                     4 
#define AF_CHAOS                   5 
#define AF_NS                      6 
#define AF_IPX                     6 
#define AF_ISO                     7 
#define AF_OSI                     7 
#define AF_ECMA                    8 
#define AF_DATAKIT                 9 
#define AF_CCITT                   10 
#define AF_SNA                     11 
#define AF_DECnet                  12 
#define AF_DLI                     13 
#define AF_LAT                     14 
#define AF_HYLINK                  15 
#define AF_APPLETALK               16 
#define AF_NETBIOS                 17 
#define AF_VOICEVIEW               18 
#define AF_FIREFOX                 19 
#define AF_UNKNOWN1                20 
#define AF_BAN                     21 
#define AF_ATM                     22 
#define AF_INET6                   23 
#define AF_CLUSTER                 24 
#define AF_12844                   25 
#define AF_IRDA                    26 
#define AF_MAX                     27 
#define PF_UNSPEC                  0 
#define PF_UNIX                    1 
#define PF_INET                    2 
#define PF_IMPLINK                 3 
#define PF_PUP                     4 
#define PF_CHAOS                   5 
#define PF_NS                      6 
#define PF_IPX                     6 
#define PF_ISO                     7 
#define PF_OSI                     7 
#define PF_ECMA                    8 
#define PF_DATAKIT                 9 
#define PF_CCITT                   10 
#define PF_SNA                     11 
#define PF_DECnet                  12 
#define PF_DLI                     13 
#define PF_LAT                     14 
#define PF_HYLINK                  15 
#define PF_APPLETALK               16 
#define PF_VOICEVIEW               18 
#define PF_FIREFOX                 19 
#define PF_UNKNOWN1                20 
#define PF_BAN                     21 
#define PF_MAX                     27 

// Types 
#define SOCK_STREAM                1 
#define SOCK_DGRAM                 2 
#define SOCK_RAW                   3 
#define SOCK_RDM                   4 
#define SOCK_SEQPACKET             5 

// Protocols 
#define IPPROTO_IP                 0 
#define IPPROTO_ICMP               1 
#define IPPROTO_IGMP               2 
#define IPPROTO_GGP                3 
#define IPPROTO_TCP                6 
#define IPPROTO_UDP                17 
#define IPPROTO_IDP                22 
#define IPPROTO_ND                 77 
#define IPPROTO_RAW                255 
#define IPPROTO_MAX                256 

// Services 
#define IPPORT_ECHO                7 
#define IPPORT_DISCARD             9 
#define IPPORT_SYSTAT              11 
#define IPPORT_DAYTIME             13 
#define IPPORT_NETSTAT             15 
#define IPPORT_FTP                 21 
#define IPPORT_TELNET              23 
#define IPPORT_SMTP                25 
#define IPPORT_TIMESERVER          37 
#define IPPORT_NAMESERVER          42 
#define IPPORT_WHOIS               43 
#define IPPORT_MTP                 57 
#define IPPORT_TFTP                69 
#define IPPORT_RJE                 77 
#define IPPORT_FINGER              79 
#define IPPORT_TTYLINK             87 
#define IPPORT_SUPDUP              95 
#define IPPORT_EXECSERVER          512 
#define IPPORT_LOGINSERVER         513 
#define IPPORT_CMDSERVER           514 
#define IPPORT_EFSSERVER           520 
#define IPPORT_BIFFUDP             512 
#define IPPORT_WHOSERVER           513 
#define IPPORT_ROUTESERVER         520 
#define IPPORT_RESERVED            1024 

// Maximum queue length specifiable by listen. 
#define SOMAXCONN                  5 
#define MSG_OOB                    1 
#define MSG_PEEK                   2 
#define MSG_DONTROUTE              4 
#define MSG_MAXIOVLEN              10 
#define MSG_PARTIAL                32768 


#define WS_BIGENDIAN 0 

// struct WSAData {
//   short          wVersion;
//   short          wHighVersion;
//   char           szDescription[WSADESCRIPTION_LEN+1];
//   char           szSystemStatus[WSASYS_STATUS_LEN+1];
//   unsigned short iMaxSockets;
//   unsigned short iMaxUdpDg;
//   char FAR       *lpVendorInfo;  
// };

struct WSAData_stream {
	char data[400];
};


struct sockaddr_in
{
  short   sin_family;
  ushort  sin_port;
  ulong   sin_addr; // additional 8 byte structure
  char    sin_zero[8];
};

struct sockaddr_in_stream
{
  uchar data[2+2+8+8];
};

