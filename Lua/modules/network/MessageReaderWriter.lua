local Class = createClass{name="MessageReaderWriter",bases={"network.Serializer"}};

local enums = require "mt5.Enums"

--[[
Class: network.MessageReaderWriter

This class is used to read/write messages from MT5 app.

This class inherits from <network.Serializer>.
]]

--[=[
--[[
Constructor: MessageReaderWriter

Create a new instance of the class.

Parameters:
	 No parameter
]]
function MessageReaderWriter(options)
]=]
function Class:initialize(options)
	-- list of static schemas	
	self._schemas = {}
	self._endianness = "< "
	self._messageHeader = self._endianness.."mtype:u2"

	self:registerSplice("timetag",{
		"year:u2", 
		"month:u1",
		"day:u1",
		"hours:u1",
		"mins:u1",
		"secs:u1",
		"msecs:u2",
	})

	-- register some the default schemas:
	self:registerSchema(enums.MSGTYPE_BALANCE_UPDATED,{
		"marketType:u1", -- market type should be either REAL or VIRTUAL for now
		"time:{ &timetag }",
		"value:f8",
	})

	self:registerSchema(enums.MSGTYPE_PORTFOLIO_STARTED,{})

	self:registerSchema(enums.MSGTYPE_TRADER_WEIGHT_UPDATED,{
		"symbol:c4",
		"time:{ &timetag }",
		"value:f8"	
	})

	self:registerSchema(enums.MSGTYPE_TRADER_UTILITY_UPDATED,{
		"symbol:c4",
		"time:{ &timetag }",
		"value:f8"	
	})
end

--[[
Function: registerSchema

Method used to register a schema, 
can either be a table, or a function for advanced
schema processing.
]]
function Class:registerSchema(id,schema)
	self:check(id,"Invalid schema name")
	self:check(schema,"Invalid schema")

	if type(schema) == "table" then
		self._schemas[id] = self._endianness .. table.concat(schema," ")
	elseif type(schema) == "function" then
		self._schemas[id] = schema
	else
		self:throw("Unsupported schema type: ", type(schema))
	end
end

--[[
Function: readMessage

Method used to read a message from a binary stream
]]
function Class:readMessage(data)
	-- We prepare the table to hold the result message:
	local tt = {}

	-- first we need to read the message type:
	-- note that the messages are written in little endian from MT5
	data = self:readStream(data,self._messageHeader,tt)

	-- Now we check if we have a schema to read this message:
	local schema = self._schemas[tt.mtype]
	if not schema then
		self:error("Cannot find schema for message type: ", tt.mtype)
		return;
	end

	if type(schema)=="string" then
		data = self:readStream(data,schema,tt)
	elseif type(schema)=="function" then
		self:soft_no_impl()
	end

	-- there should be no data left to read in that message buffer:
	self:check(#data == 0,"There is some data left to read: ", #data)

	-- return the decrypted message:
	return tt
end

--[[
Function: writeMessage

Method used to write a message to binary stream
]]
function Class:writeMessage(tt)
	
	local data = self:writeStream(self._messageHeader,tt)

	-- Now we check if we have a schema to read this message:
	local schema = self._schemas[tt.mtype]
	if not schema then
		self:error("Cannot find schema for message type: ", tt.mtype)
		return;
	end

	if type(schema)=="string" then
		data = data .. self:writeStream(schema,tt)
	elseif type(schema)=="function" then
		self:soft_no_impl()
	end

	-- return the data stream:
	return data
end


return Class
