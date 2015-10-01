local Class = createClass{name="BalancePlot",bases={"base.EventHandler","mt5.Enums"}};

--[[
Class: gui.BalancePlot

Simple class used to display a balance on a graph

This class inherits from <base.Object>.
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
	self._plot = iup.plot{
		--    TITLE = "Plot Test",
    MARGINBOTTOM = 30,
    GRAPHICSMODE = "opengl",
	}

	self._panel = iup.vbox{self._plot,gap=2}
	self._panel.tabtitle="Balance Plot"

	-- simple demo graph:
	self._plot:Begin(0)
	-- self._plot:Add(0, 0)
	-- self._plot:Add(1, 1)
	self._index = self._plot:End()

	-- self:addSample(0,0)
	-- self:addSample(1,2)

	local x = 0
	self:on("msg_" .. Class.MSGTYPE_BALANCE_VALUE,function(msg)
		-- self:debug("Should handle the balance value message here")
		self:addSample(x,msg.value)		
		x = x+1
	end)
end

--[[
Function: addSample

Method used to add a sample
]]
function Class:addSample(x,y)
	self._plot:AddSamples(self._index, {x}, {y}, 1)
	self._plot.redraw="yes"
end

--[[
Function: getPanel

Retrieve the IUP panel for this component
]]
function Class:getPanel()
	return self._panel
end


return Class
