local Class = createClass{name="FileLogger",bases={"log.LogSink"}};

--[[
Class: log.FileLogger

File logger class

This class inherits from <log.LogSink>.
]]

--[=[
--[[
Constructor: FileLogger

Create a new instance of the class.

Parameters:
	 No parameter
]]
function FileLogger(options)
]=]
function Class:initialize(options)
	self._file = io.open(options.file,"w")
	if not self._file then
		error("Cannot open file ".. options.file)
	end
end

--[[
Function: output

Method to output a message.
]]
function Class:output(level,trace,msg)
	self._file:write(msg)
	self._file:flush()
end

--[[
Function: release

Release the file handle
]]
function Class:release()
	self._file:close()
end



return Class