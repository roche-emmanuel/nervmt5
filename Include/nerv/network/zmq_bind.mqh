#include <nerv/core.mqh>

// Bindings for zeromq direct usage:

#import "msvcrt.dll"
  long memcpy(long dst, long src, long cnt);
  long memcpy(const char &dst[], const char &src[], long cnt);
#import "libzmq.dll"
int zmq_errno (void);
// void zmq_version (int *major, int *minor, int *patch);

long zmq_ctx_new (void);
int zmq_ctx_term (long context);

int zmq_ctx_shutdown (long context);
int zmq_ctx_set (long context, int option, int optval);
int zmq_ctx_get (long context, int option);

long zmq_socket (long context, int type);
int zmq_close (long s);
int zmq_connect (long s, const char &addr[]);
int zmq_bind (long s, const char &addr[]);

int zmq_send (long s, const char &buf[], long len, int flags);
int zmq_recv (long s, char &buf[], long len, int flags);

int zmq_msg_init (long msg);
int zmq_msg_init_size (long msg, long size);
int zmq_msg_send (long msg, long s, int flags);
int zmq_msg_recv (long msg, long s, int flags);
int zmq_msg_close (long msg);
long zmq_msg_data (long msg);
long zmq_msg_size (long msg);

// int zmq_msg_move (long dest, long src);
// int zmq_msg_copy (long dest, long src);

// int zmq_setsockopt (long s, int option, const char &optval[], long optvallen);
// int zmq_getsockopt (long s, int option, char &optval[], long &optvallen[]);
// int zmq_unbind (long s, const char &addr[]);
// int zmq_disconnect (long s, const char &addr[]);
// int zmq_send_const (long s, const char &buf[], long len, int flags);
// int zmq_socket_monitor (long s, const char &addr[], int events);

// int zmq_poll (char &items[], int nitems, long timeout);
#import

long getMemAddress(const char &array[])
{
	return memcpy(array,array,0);
}

struct zmq_msg_stream {
	uchar data[64];
};

/*  Context options                                                           */
#define ZMQ_IO_THREADS  1
#define ZMQ_MAX_SOCKETS 2
#define ZMQ_SOCKET_LIMIT 3
#define ZMQ_THREAD_PRIORITY 3
#define ZMQ_THREAD_SCHED_POLICY 4

/*  Default for new contexts                                                  */
#define ZMQ_IO_THREADS_DFLT  1
#define ZMQ_MAX_SOCKETS_DFLT 1023
#define ZMQ_THREAD_PRIORITY_DFLT -1
#define ZMQ_THREAD_SCHED_POLICY_DFLT -1

/******************************************************************************/
/*  0MQ socket definition.                                                    */
/******************************************************************************/

/*  Socket types.                                                             */
#define ZMQ_PAIR 0
#define ZMQ_PUB 1
#define ZMQ_SUB 2
#define ZMQ_REQ 3
#define ZMQ_REP 4
#define ZMQ_DEALER 5
#define ZMQ_ROUTER 6
#define ZMQ_PULL 7
#define ZMQ_PUSH 8
#define ZMQ_XPUB 9
#define ZMQ_XSUB 10
#define ZMQ_STREAM 11

/*  Deprecated aliases                                                        */
#define ZMQ_XREQ ZMQ_DEALER
#define ZMQ_XREP ZMQ_ROUTER

/*  Socket options.                                                           */
#define ZMQ_AFFINITY 4
#define ZMQ_IDENTITY 5
#define ZMQ_SUBSCRIBE 6
#define ZMQ_UNSUBSCRIBE 7
#define ZMQ_RATE 8
#define ZMQ_RECOVERY_IVL 9
#define ZMQ_SNDBUF 11
#define ZMQ_RCVBUF 12
#define ZMQ_RCVMORE 13
#define ZMQ_FD 14
#define ZMQ_EVENTS 15
#define ZMQ_TYPE 16
#define ZMQ_LINGER 17
#define ZMQ_RECONNECT_IVL 18
#define ZMQ_BACKLOG 19
#define ZMQ_RECONNECT_IVL_MAX 21
#define ZMQ_MAXMSGSIZE 22
#define ZMQ_SNDHWM 23
#define ZMQ_RCVHWM 24
#define ZMQ_MULTICAST_HOPS 25
#define ZMQ_RCVTIMEO 27
#define ZMQ_SNDTIMEO 28
#define ZMQ_LAST_ENDPOINT 32
#define ZMQ_ROUTER_MANDATORY 33
#define ZMQ_TCP_KEEPALIVE 34
#define ZMQ_TCP_KEEPALIVE_CNT 35
#define ZMQ_TCP_KEEPALIVE_IDLE 36
#define ZMQ_TCP_KEEPALIVE_INTVL 37
#define ZMQ_IMMEDIATE 39
#define ZMQ_XPUB_VERBOSE 40
#define ZMQ_ROUTER_RAW 41
#define ZMQ_IPV6 42
#define ZMQ_MECHANISM 43
#define ZMQ_PLAIN_SERVER 44
#define ZMQ_PLAIN_USERNAME 45
#define ZMQ_PLAIN_PASSWORD 46
#define ZMQ_CURVE_SERVER 47
#define ZMQ_CURVE_PUBLICKEY 48
#define ZMQ_CURVE_SECRETKEY 49
#define ZMQ_CURVE_SERVERKEY 50
#define ZMQ_PROBE_ROUTER 51
#define ZMQ_REQ_CORRELATE 52
#define ZMQ_REQ_RELAXED 53
#define ZMQ_CONFLATE 54
#define ZMQ_ZAP_DOMAIN 55
#define ZMQ_ROUTER_HANDOVER 56
#define ZMQ_TOS 57
#define ZMQ_CONNECT_RID 61
#define ZMQ_GSSAPI_SERVER 62
#define ZMQ_GSSAPI_PRINCIPAL 63
#define ZMQ_GSSAPI_SERVICE_PRINCIPAL 64
#define ZMQ_GSSAPI_PLAINTEXT 65
#define ZMQ_HANDSHAKE_IVL 66
#define ZMQ_SOCKS_PROXY 68
#define ZMQ_XPUB_NODROP 69

/*  Message options                                                           */
#define ZMQ_MORE 1
#define ZMQ_SRCFD 2
#define ZMQ_SHARED 3

/*  Send/recv options.                                                        */
#define ZMQ_DONTWAIT 1
#define ZMQ_SNDMORE 2

/*  Security mechanisms                                                       */
#define ZMQ_NULL 0
#define ZMQ_PLAIN 1
#define ZMQ_CURVE 2
#define ZMQ_GSSAPI 3

/*  Deprecated options and aliases                                            */
#define ZMQ_TCP_ACCEPT_FILTER       38
#define ZMQ_IPC_FILTER_PID          58
#define ZMQ_IPC_FILTER_UID          59
#define ZMQ_IPC_FILTER_GID          60
#define ZMQ_IPV4ONLY                31
#define ZMQ_DELAY_ATTACH_ON_CONNECT ZMQ_IMMEDIATE
#define ZMQ_NOBLOCK                 ZMQ_DONTWAIT
#define ZMQ_FAIL_UNROUTABLE         ZMQ_ROUTER_MANDATORY
#define ZMQ_ROUTER_BEHAVIOR         ZMQ_ROUTER_MANDATORY

/******************************************************************************/
/*  0MQ socket events and monitoring                                          */
/******************************************************************************/

/*  Socket transport events (TCP and IPC only)                                */

#define ZMQ_EVENT_CONNECTED         0x0001
#define ZMQ_EVENT_CONNECT_DELAYED   0x0002
#define ZMQ_EVENT_CONNECT_RETRIED   0x0004
#define ZMQ_EVENT_LISTENING         0x0008
#define ZMQ_EVENT_BIND_FAILED       0x0010
#define ZMQ_EVENT_ACCEPTED          0x0020
#define ZMQ_EVENT_ACCEPT_FAILED     0x0040
#define ZMQ_EVENT_CLOSED            0x0080
#define ZMQ_EVENT_CLOSE_FAILED      0x0100
#define ZMQ_EVENT_DISCONNECTED      0x0200
#define ZMQ_EVENT_MONITOR_STOPPED   0x0400
#define ZMQ_EVENT_ALL               0xFFFF

#define ZMQ_POLLIN 1
#define ZMQ_POLLOUT 2
#define ZMQ_POLLERR 4
#define ZMQ_POLLITEMS_DFLT 16


// Errno from linux:

#define EPERM            1      /* Operation not permitted */
#define ENOENT           2      /* No such file or directory */
#define ESRCH            3      /* No such process */
#define EINTR            4      /* Interrupted system call */
#define EIO              5      /* I/O error */
#define ENXIO            6      /* No such device or address */
#define E2BIG            7      /* Arg list too long */
#define ENOEXEC          8      /* Exec format error */
#define EBADF            9      /* Bad file number */
#define ECHILD          10      /* No child processes */
#define EAGAIN          11      /* Try again */
#define ENOMEM          12      /* Out of memory */
#define EACCES          13      /* Permission denied */
#define EFAULT          14      /* Bad address */
#define ENOTBLK         15      /* Block device required */
#define EBUSY           16      /* Device or resource busy */
#define EEXIST          17      /* File exists */
#define EXDEV           18      /* Cross-device link */
#define ENODEV          19      /* No such device */
#define ENOTDIR         20      /* Not a directory */
#define EISDIR          21      /* Is a directory */
#define EINVAL          22      /* Invalid argument */
#define ENFILE          23      /* File table overflow */
#define EMFILE          24      /* Too many open files */
#define ENOTTY          25      /* Not a typewriter */
#define ETXTBSY         26      /* Text file busy */
#define EFBIG           27      /* File too large */
#define ENOSPC          28      /* No space left on device */
#define ESPIPE          29      /* Illegal seek */
#define EROFS           30      /* Read-only file system */
#define EMLINK          31      /* Too many links */
#define EPIPE           32      /* Broken pipe */
#define EDOM            33      /* Math argument out of domain of func */
#define ERANGE          34      /* Math result not representable */
#define EDEADLK         35      /* Resource deadlock would occur */
#define ENAMETOOLONG    36      /* File name too long */
#define ENOLCK          37      /* No record locks available */
#define ENOSYS          38      /* Function not implemented */
#define ENOTEMPTY       39      /* Directory not empty */
#define ELOOP           40      /* Too many symbolic links encountered */
#define EWOULDBLOCK     EAGAIN  /* Operation would block */
#define ENOMSG          42      /* No message of desired type */
#define EIDRM           43      /* Identifier removed */
#define ECHRNG          44      /* Channel number out of range */
#define EL2NSYNC        45      /* Level 2 not synchronized */
#define EL3HLT          46      /* Level 3 halted */
#define EL3RST          47      /* Level 3 reset */
#define ELNRNG          48      /* Link number out of range */
#define EUNATCH         49      /* Protocol driver not attached */
#define ENOCSI          50      /* No CSI structure available */
#define EL2HLT          51      /* Level 2 halted */
#define EBADE           52      /* Invalid exchange */
#define EBADR           53      /* Invalid request descriptor */
#define EXFULL          54      /* Exchange full */
#define ENOANO          55      /* No anode */
#define EBADRQC         56      /* Invalid request code */
#define EBADSLT         57      /* Invalid slot */

#define EDEADLOCK       EDEADLK

#define EBFONT          59      /* Bad font file format */
#define ENOSTR          60      /* Device not a stream */
#define ENODATA         61      /* No data available */
#define ETIME           62      /* Timer expired */
#define ENOSR           63      /* Out of streams resources */
#define ENONET          64      /* Machine is not on the network */
#define ENOPKG          65      /* Package not installed */
#define EREMOTE         66      /* Object is remote */
#define ENOLINK         67      /* Link has been severed */
#define EADV            68      /* Advertise error */
#define ESRMNT          69      /* Srmount error */
#define ECOMM           70      /* Communication error on send */
#define EPROTO          71      /* Protocol error */
#define EMULTIHOP       72      /* Multihop attempted */
#define EDOTDOT         73      /* RFS specific error */
#define EBADMSG         74      /* Not a data message */
#define EOVERFLOW       75      /* Value too large for defined data type */
#define ENOTUNIQ        76      /* Name not unique on network */
#define EBADFD          77      /* File descriptor in bad state */
#define EREMCHG         78      /* Remote address changed */
#define ELIBACC         79      /* Can not access a needed shared library */
#define ELIBBAD         80      /* Accessing a corrupted shared library */
#define ELIBSCN         81      /* .lib section in a.out corrupted */
#define ELIBMAX         82      /* Attempting to link in too many shared libraries */
#define ELIBEXEC        83      /* Cannot exec a shared library directly */
#define EILSEQ          84      /* Illegal byte sequence */
#define ERESTART        85      /* Interrupted system call should be restarted */
#define ESTRPIPE        86      /* Streams pipe error */
#define EUSERS          87      /* Too many users */
#define ENOTSOCK        88      /* Socket operation on non-socket */
#define EDESTADDRREQ    89      /* Destination address required */
#define EMSGSIZE        90      /* Message too long */
#define EPROTOTYPE      91      /* Protocol wrong type for socket */
#define ENOPROTOOPT     92      /* Protocol not available */
#define EPROTONOSUPPORT 93      /* Protocol not supported */
#define ESOCKTNOSUPPORT 94      /* Socket type not supported */
#define EOPNOTSUPP      95      /* Operation not supported on transport endpoint */
#define EPFNOSUPPORT    96      /* Protocol family not supported */
#define EAFNOSUPPORT    97      /* Address family not supported by protocol */
#define EADDRINUSE      98      /* Address already in use */
#define EADDRNOTAVAIL   99      /* Cannot assign requested address */
#define ENETDOWN        100     /* Network is down */
#define ENETUNREACH     101     /* Network is unreachable */
#define ENETRESET       102     /* Network dropped connection because of reset */
#define ECONNABORTED    103     /* Software caused connection abort */
#define ECONNRESET      104     /* Connection reset by peer */
#define ENOBUFS         105     /* No buffer space available */
#define EISCONN         106     /* Transport endpoint is already connected */
#define ENOTCONN        107     /* Transport endpoint is not connected */
#define ESHUTDOWN       108     /* Cannot send after transport endpoint shutdown */
#define ETOOMANYREFS    109     /* Too many references: cannot splice */
#define ETIMEDOUT       110     /* Connection timed out */
#define ECONNREFUSED    111     /* Connection refused */
#define EHOSTDOWN       112     /* Host is down */
#define EHOSTUNREACH    113     /* No route to host */
#define EALREADY        114     /* Operation already in progress */
#define EINPROGRESS     115     /* Operation now in progress */
#define ESTALE          116     /* Stale NFS file handle */
#define EUCLEAN         117     /* Structure needs cleaning */
#define ENOTNAM         118     /* Not a XENIX named type file */
#define ENAVAIL         119     /* No XENIX semaphores available */
#define EISNAM          120     /* Is a named type file */
#define EREMOTEIO       121     /* Remote I/O error */
#define EDQUOT          122     /* Quota exceeded */

#define ENOMEDIUM       123     /* No medium found */
#define EMEDIUMTYPE     124     /* Wrong medium type */
