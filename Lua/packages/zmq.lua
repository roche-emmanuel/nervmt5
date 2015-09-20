-- definition of ZMQ bindings:

local ffi = require("ffi")
ffi.cdef[[
int zmq_errno (void);
void *zmq_ctx_new (void);
int zmq_ctx_term (void *context);

void *zmq_socket (void *, int type);
int zmq_close (void *s);
int zmq_bind (void *s, const char *addr);
int zmq_connect (void *s, const char *addr);

typedef struct zmq_msg_t {unsigned char _ [64];} zmq_msg_t;

int zmq_msg_init (zmq_msg_t *msg);
int zmq_msg_init_size (zmq_msg_t *msg, size_t size);
int zmq_msg_send (zmq_msg_t *msg, void *s, int flags);
int zmq_msg_recv (zmq_msg_t *msg, void *s, int flags);
int zmq_msg_close (zmq_msg_t *msg);
void *zmq_msg_data (zmq_msg_t *msg);
size_t zmq_msg_size (zmq_msg_t *msg);
]]

local lib = ffi.load("libzmq")

local zmq = {}

-- definitions:
zmq.PAIR 		= 0
zmq.PUB 		= 1
zmq.SUB 		= 2
zmq.REQ 		= 3
zmq.REP 		= 4
zmq.DEALER 	= 5
zmq.ROUTER 	= 6
zmq.PULL 		= 7
zmq.PUSH 		= 8
zmq.XPUB 		= 9
zmq.XSUB 		= 10
zmq.STREAM 	= 11

--  Send/recv options.
zmq.DONTWAIT	= 1
zmq.SNDMORE		= 2

-- error codes:
zmq.EAGAIN = 11

-- Context handling:

local context = nil

local close_context = function(c)
	print("Closing context object.")
	local res = lib.zmq_ctx_term(c);
	if res ~= 0 then
		error("Error in zmq_ctx_term(): error: ".. lib.zmq_errno());
	end
end

zmq.init = function()
	if context == nil then
		print("Initializing ZMQ context.")
		context = lib.zmq_ctx_new();
		if context==nil then
			error("Error in zmq_ctx_new(): error: ".. lib.zmq_errno());
		else
			ffi.gc(context,close_context)	
		end
	end
end

zmq.uninit = function()
	if context ~= nil then
		ffi.gc(context,nil)
		close_context(context)
		context = nil
	end
end

-- Socket handling:
local Socket = {}

function Socket:new(stype)
	
	local o = {}
	o._s = nil;
	o._msg = ffi.new("zmq_msg_t[1]");

  setmetatable(o, self)
  self.__index = self
  
  o:open(stype)
  return o
end

local close_socket = function(s)
	print("Closing socket object.")
	if lib.zmq_close(s) ~= 0 then
		error("Error in zmq_close(): error: ".. lib.zmq_errno())
	end
end

function Socket:close()
	if self._s then
		ffi.gc(self._s,nil)
		close_socket(self._s)
		self._s = nil
	end
end

function Socket:open(stype)
	self:close()

	zmq.init()

	self._s = lib.zmq_socket(context,stype);
	if self._s == nil then
		error("Error in zmq_socket(): error: ".. lib.zmq_errno())
	else
		ffi.gc(self._s,close_socket)
	end
end

function Socket:bind(endpoint)
	assert(self._s)
	if lib.zmq_bind(self._s,endpoint) ~= 0 then
		error("Error in zmq_bind(): error: ".. lib.zmq_errno())
	end
end

function Socket:connect(endpoint)
	assert(self._s)
	if lib.zmq_connect(self._s,endpoint) ~= 0 then
		error("Error in zmq_connect(): error: ".. lib.zmq_errno())
	end
end

function Socket:send(msg)
	assert(self._s)

	local len = #msg
	if len==0 then
		return --nothing to send.
	end

	if lib.zmq_msg_init_size(self._msg,len) ~= 0 then
		error("Error in zmq_msg_init_size(): error: ".. lib.zmq_errno())
	end

	ffi.copy(lib.zmq_msg_data(self._msg), msg, len);

	if lib.zmq_msg_send(self._msg,self._s,zmq.DONTWAIT) ~= len then
		error("Error in zmq_msg_send(): error: ".. lib.zmq_errno())
	end

	if lib.zmq_msg_close(self._msg) ~= 0 then
		error("Error in zmq_msg_close(): error: ".. lib.zmq_errno())
	end
end

function Socket:receive()
	assert(self._s)

	if lib.zmq_msg_init(self._msg) ~= 0 then
		error("Error in zmq_msg_init(): error: ".. lib.zmq_errno())
	end

  local len = lib.zmq_msg_recv(self._msg,self._s,zmq.DONTWAIT)
  if len<0 then
    local err = lib.zmq_errno();
    if err ~= zmq.EAGAIN then
      error("Error in zmq_msg_recv(): error: " .. err);
    end
  elseif len==0 then
    error("Error in zmq_msg_recv(): received a message with length 0.");
  end

  local msg = nil

  if len>0 then
  	msg = ffi.string(lib.zmq_msg_data(self._msg),len);
  end

	if lib.zmq_msg_close(self._msg) ~= 0 then
		error("Error in zmq_msg_close(): error: ".. lib.zmq_errno())
	end

	return msg
end


-- method used to create a socket:
zmq.socket = function(stype)
	return Socket:new(stype)
end


return zmq;
