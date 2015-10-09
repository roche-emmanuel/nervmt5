local Class = createClass{name="TraderWeightPlot",bases={"gui.BasePlot"}};

--[[
Class: gui.TraderWeightPlot

Simple class used to display trader weight evolution on a graph

This class inherits from <gui.BasePlot>.
]]

--[=[
--[[
Constructor: TraderWeightPlot

Create a new instance of the class.

Parameters:
	 No parameter
]]
function TraderWeightPlot(options)
]=]
function Class:initialize(options)
	local x = 0
	self:on("msg_" .. Class.MSGTYPE_TRADER_WEIGHT_UPDATED,function(msg)
		-- self:debug("Should handle the balance value message here")
		self:addSample(x,msg.value,msg.symbol)		
		x = x+1
		self._updatedNeeded = true
	end)
end

return Class
