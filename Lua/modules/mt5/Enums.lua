local Class = createClass{name="Enums",bases={"base.Object"}};

-- List of genering events:
Class.EVT_TIMER = "timer"

-- List of message type:
Class.MSGTYPE_UNKNOWN 				  = 0
Class.MSGTYPE_BALANCE_UPDATED 	= 1


-- Type of market:
Class.MARKET_UNKNOWN 	= 0
Class.MARKET_REAL 		= 1
Class.MARKET_VIRTUAL 	= 2


--[[
Class: mt5.Enums

List of enumerations for MT5

This class inherits from <base.Object>.
]]

--[=[
--[[
Constructor: Enums

Create a new instance of the class.

Parameters:
	 No parameter
]]
function Enums(options)
]=]
function Class:initialize(options)
	-- Function body
end

return Class
