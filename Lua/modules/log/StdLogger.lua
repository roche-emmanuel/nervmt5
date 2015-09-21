local Class = createClass{name="StdLogger",bases={"log.LogSink"}};

--[[
Class: log.StdLogger

Console logger class

This class inherits from <log.LogSink>.
]]

--[=[
--[[
Constructor: StdLogger

Create a new instance of the class.

Parameters:
	 No parameter
]]
function StdLogger(options)
]=]
function Class:initialize(options)
end

--[[
Function: output

Method to output a message.
]]
function Class:output(level,trace,msg)
	print(msg)
end

return Class