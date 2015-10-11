local Class = createClass{name="TraderUtilityPlot",bases={"gui.BasePlot"}};

--[[
Class: gui.TraderUtilityPlot

Simple class used to display trader weight evolution on a graph

This class inherits from <gui.BasePlot>.
]]

--[=[
--[[
Constructor: TraderUtilityPlot

Create a new instance of the class.

Parameters:
	 No parameter
]]
function TraderUtilityPlot(options)
]=]
function Class:initialize(options)
	-- local x = 0
	self:on("msg_" .. Class.MSGTYPE_TRADER_UTILITY_UPDATED,function(msg)
		-- self:debug("Should handle the balance value message here")
		self:addTimedSample(msg.time,msg.value,msg.symbol)		
		-- x = x+1
		self._updatedNeeded = true
	end)
end

return Class
