local Class = createClass{name="LogSink",bases={}};

local lm = require "log.LogManager"

--[[
Class: log.LogSink

Basic LogSink class

This class inherits from .
]]

--[=[
--[[
Constructor: LogSink

Create a new instance of the class.

Parameters:
	 No parameter
]]
function LogSink(options)
]=]
function Class:initialize(options)
	self._name = type(options)=="string" and options or options.name
end

--[[
Function: getName

Retrieve the name of this log sink
]]
function Class:getName()
	return self._name
end

--[[
Function: process

Main method to process a log message
]]
function Class:process(level,trace,msg)

	if trace and trace~="" then
		msg = ("%s [%s] <%s>\t%s"):format(os.date("%c"),lm:getLevelString(level),trace,msg)
	else
		msg = ("%s [%s]\t%s"):format(os.date("%c"),lm:getLevelString(level),msg)
	end

	self:output(level,trace,msg)
end

--[[
Function: output

Method to output a message. Should be re-implemented
]]
function Class:output(level,trace,msg)
	self:no_impl()
end

--[[
Function: release

Might be overriden to release this log sink properly.
]]
function Class:release()
	-- No op.
end

return Class