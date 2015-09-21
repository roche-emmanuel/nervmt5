local Class = createClass{name="LogManager"};

-- Severity level:

Class.SEV_FATAL = 0
Class.SEV_ERROR = 1
Class.SEV_WARNING = 2
Class.SEV_NOTICE = 3
Class.SEV_INFO = 4
Class.SEV_DEBUG = 5

local levelStr = {
	[Class.SEV_FATAL] = "Fatal",	
	[Class.SEV_ERROR] = "Error",	
	[Class.SEV_WARNING] = "Warning",	
	[Class.SEV_NOTICE] = "Notice",	
	[Class.SEV_INFO] = "Info",	
	[Class.SEV_DEBUG] = "Debug",	
}


--[[
Class: log.LogManager

Singleton object used to control the logging in lua.

This class inherits from .
]]

--[=[
--[[
Constructor: LogManager

Create a new instance of the class.

Parameters:
	 No parameter
]]
function LogManager(options)
]=]
function Class:initialize(options)
	self._sinks = {}
	self._notifyLevel = Class.DEBUG
	self._verbose = true
	self._handler = nil
end

--[[
Function: getVerbose

Check if verbose is active
]]
function Class:getVerbose()
	return self._verbose
end

--[[
Function: setVerbose

Set the verbose state for this singleton
]]
function Class:setVerbose(enabled)
	self._verbose = enabled
end

--[[
Function: getNotifyLevel

Retrieve the current notify level
]]
function Class:getNotifyLevel()
	return self._notifyLevel
end

--[[
Function: setNotifyLevel

Assign notification level
]]
function Class:setNotifyLevel(level)
	self._notifyLevel = level
end

--[[
Function: log

Facade method called to do the logging
]]
function Class:log(level,trace,msg)
	if self._handler then
		self._handler(level,trace,msg)
	else
		self:doLog(level,trace,msg)
	end
end

--[[
Function: doLog

Perform the actual log by this LogManager
]]
function Class:doLog(level,trace,msg)
	if #self._sinks == 0 then
		table.insert(self._sinks, require "log.StdLogger" ("default_console_sink") )
	end

	for _,sink in ipairs(self._sinks) do
		sink:process(level,trace,msg)
	end
end

--[[
Function: removeAllSinks

Remove all the log sinks
]]
function Class:removeAllSinks()
	for _,sink in ipairs(self._sinks) do
		sink:release()
	end
	self._sinks = {}
end

--[[
Function: getSink

Retrieve a LogSink by name
]]
function Class:getSink(name)
	for _,sink in ipairs(self._sinks) do
		if sink:getName() == name then
			return sink
		end
	end
end

--[[
Function: removeSink

Remove a log sink by name
]]
function Class:removeSink(name)
	for k,sink in ipairs(self._sinks) do
		if sink:getName() == name then
			return table.remove(self._sinks,k)
		end
	end	
end

--[[
Function: addSink

Add a LogSink object
]]
function Class:addSink(sink)
	if sink then
		table.insert(self._sinks,sink)
	end
end

--[[
Function: release

Release the log manager
]]
function Class:release()
	self:removeAllSinks()
end

--[[
Function: getLevelString

Retrieve a string for a log severity
]]
function Class:getLevelString(level)
	return levelStr[level] or "NONE"
end

return Class()
