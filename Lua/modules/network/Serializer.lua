local Class = createClass{name="Serializer",bases={"base.Object"}};

local vstruct = require "vstruct.init"

log:debug("Using vstruct version: ",vstruct._VERSION)	

--[[
Class: network.Serializer

Helper class providing support for serialization and
deserialization operations. It is basically an encapsulation
of the vstruct functionlalities.

This class will mainly provide the <writeStream> and
<readStream> methods.

It also provide support for pretty printing objects with its method
<print>.

This class inherits from <base.Object>.
]]

--[=[
--[[
Constructor: Serializer

Create a new instance of the class.

Parameters:
	 No parameter
]]
function Serializer(options)
]=]
function Class:initialize(options)
end

--[[
Function: registerSplice

Method used to register a splice on vstruct
]]
function Class:registerSplice(name,schema)
	self:check(name,"Invalid splice name")
	self:check(schema,"Invalid splice schema")

	vstruct.compile(name, table.concat(schema," "))
end

--[[
Function: writeStream

Base method used to perform the actual write to stream 
operation. This method is used by this class and derived classes
implementation of write()

Parameters:
  schema - The schema to use during the write
	tt - The table of data to write (or self by default)
Returns: 
	The written stream.
]]
function Class:writeStream(schema, tt)
	if not schema then
		return ""; -- nothing to write
	end
	return vstruct.write(schema, tt or self)
end

--[[
Function: readStream

Base method used to read a schema from a stream. This is used in
this class with the <read> method and in derived classes.

Parameters:
  data - The stream to read from
	schema - The schema to use when reading.
	tt - the target table where to store the values.

Returns:
	The part of the data stream that is not read yet.
]]
function Class:readStream(data,schema,tt)
	if not schema then
		return data; -- nothing to read
	end
	local cur = vstruct.cursor(data)
	vstruct.read(schema,cur,tt or self)
	-- self:debug("Read position: ", cur.pos)
	-- return only what's left to read.
	-- Note here that the cursor position is 0-based and Lua is 1-based:
	return data:sub(cur.pos+1) 	
end


return Class
