local Class = createClass{name="MT5Control",bases={"base.Object"}};

require "iuplua"
require "cdlua"
require "imlua"
require "imlua_process"
require "iupluaim"
require "iupluacontrols"

local lm = require "log.LogManager"
local im = require "gui.ImageManager"
local zmq = require "zmq"

--[[
Class: gui.MT5Control

Main interface definition for the MT5 Control app.

This class inherits from <base.Object>.
]]

--[=[
--[[
Constructor: MT5Control

Create a new instance of the class.

Parameters:
	 No parameter
]]
function MT5Control(options)
]=]
function Class:initialize(options)
	self._reload = false

	-- Main Application GUI.
	local reload_btn = iup.button{title = "Reload", image=im:getImage("refresh")}
	local clear_btn = iup.button{title = "Clear", image=im:getImage("delete")}
	local test_btn = iup.button{title = "Test", image=im:getImage("test")}
	local unittest_btn = iup.button{title = "UnitTests", image=im:getImage("check")}

	local line = iup.hbox { reload_btn, clear_btn, unittest_btn, test_btn, gap=2, alignment="acenter"}

	local logArea = iup.multiline{expand = "YES", appendnewline="no", formatting="yes"}

	self:createLogSink(logArea)

	local col = iup.vbox { line, logArea, gap=2, margin="1x1" }
	dlg = iup.dialog{col; title="MT5 Control", size="400x200", icon=im:getImage("nerv")}
	dlg:show()

	reload_btn.action = function()
		self._reload = true
		dlg:destroy()
		return iup.CLOSE
	end

	clear_btn.action = function()
		logArea.value = ""
	end

	test_btn.action = function()
		self:debug("Sending message...")

		PROTECT(function()
			-- Create a ZMQ client and send data:
		  local client = zmq.socket(zmq.PUSH);
		  client:connect("tcp://localhost:22223");

		  client:send("Hello world!")
		  -- client:close()
	  end)
  end

	unittest_btn.action = function()
		return self:performUnitTests(logArea)
	end

	-- Allocate a Message handler component:
	self._handler = require "network.MessageHandler" ()

	self:initSockets()
	self:initTimer()

  self:debug("MT5 control ready.")
end

--[[
Function: performUnitTests

Method used to perform the unit tests
]]
function Class:performUnitTests(logArea)
	if self._unittest_co then
		self:warn("Unit tests are already running.")
		return iup.DEFAULT
	end

	self._unittest_co = nil
	function on_idle()
		if self._unittest_co then
			-- self:debug("Resuming unit test coroutine...")
			coroutine.resume(self._unittest_co)

			if coroutine.status(self._unittest_co) == "dead" then
				-- self:debug("Unit test coroutine is done.")
				self._unittest_co = nil
			end
		else
			iup.SetIdle(nil)
			self:debug("Done executing unit tests.")
		end
	end

	local threadfn = function()
		local status,res = pcall(function()
			-- ensure that we reload the test files before starting:
			unloadModules{"tests%.","telescope%."}
			-- place the caret at the end of the logArea control:
			logArea.scrollto = (logArea.linecount+1)..":"..1

			-- Then we execute the tests:
			require "telescope.launcher" ()

			-- place the caret at the end of the logArea control:
			logArea.scrollto = (logArea.linecount+1)..":"..1
		end)
		if not status then
			self:error("In test: ",res)
		end	
	end

	self._unittest_co = coroutine.create(threadfn)
	iup.SetIdle(on_idle)
	return iup.DEFAULT
end

--[[
Function: initSockets

Methoc called during initialization to setup the ZMQ sockets
]]
function Class:initSockets()
	PROTECT(function()
		self._server = zmq.socket(zmq.PULL)

		self:debug("Binding server...")
		self._server:bind("tcp://*:22223")
	end)
end

--[[
Function: initTimer

Methoc called during initialization to setup the timer for
ZMQ reception:
]]
function Class:initTimer()
	self._timer = iup.timer{time=50}


	self._timer.action_cb = function()
		PROTECT(function()
			self:onTimer()
		end)
	end	

	self._timer.run = "yes"
end

--[[
Function: onTimer

Callbeck called to handle a timer event
]]
function Class:onTimer()
	-- self:debug("Executing timer callback...")	
  local msg = self._server:receive()
  local tt
  while msg do
  	tt = self._handler:readMessage(msg)
  	if tt then
	  	self:debug("Received message: ",tt)
	  else
	  	self:warn("Cannot parse message: '", msg:toHex(),"', ascii: '",msg,"'")
	  end
  	msg = self._server:receive()
  end
end

--[[
Function: createLogSink

Create the default log sink
]]
function Class:createLogSink(target)
	-- Implement a minimal log sink class here:
	local LogClass = createClass{name="GUILogSink",bases={"log.LogSink"}}

	local levelColors = {
		[lm.SEV_FATAL]="200 0 0",
		[lm.SEV_ERROR]="255 0 0",
		[lm.SEV_WARNING]="255 128 0",
		[lm.SEV_NOTICE]="0 120 0",
		[lm.SEV_INFO]="0 0 120",
	}

	function LogClass:output(level,trace,msg)
		target.addformattag = iup.user { fgcolor = levelColors[level] or "0 0 0" }
		target.append = msg .. '\n'
	end
	
	lm:removeAllSinks()

	-- Connect the log sink:
	lm:addSink(LogClass())
end

--[[
Function: run

Main function to run this app.
]]
function Class:run()
	--  Execute the main loop of IUP:
	if (iup.MainLoopLevel()==0) then
	  iup.MainLoop()
	end	

	-- Stop the timer:
	self._timer.run = "no"

	-- close the server:
	self._server:close()

	-- release the log manager:
	lm:release()

	return self._reload
end

-- return singleton:
return Class()
