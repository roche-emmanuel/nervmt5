local Class = createClass{name="BalancePlot",bases={"gui.BasePlot"}};

--[[
Class: gui.BalancePlot

Simple class used to display a balance on a graph

This class inherits from <gui.BasePlot>.
]]

--[=[
--[[
Constructor: BalancePlot

Create a new instance of the class.

Parameters:
	 No parameter
]]
function BalancePlot(options)
]=]
function Class:initialize(options)
	-- local x = 0
	self:on("msg_" .. Class.MSGTYPE_BALANCE_UPDATED,function(msg)
		-- self:debug("Should handle the balance value message here")
		self:addTimedSample(msg.time,msg.value,"Balance")		
		-- x = x+1
		self._updatedNeeded = true
	end)
end

return Class
