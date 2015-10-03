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

	local x = 0
	self:on("msg_" .. Class.MSGTYPE_BALANCE_UPDATED,function(msg)
		-- self:debug("Should handle the balance value message here")
		self:addSample(x,msg.value)		
		x = x+1
		self._updatedNeeded = true
	end)

	self:on("msg_" .. Class.MSGTYPE_PORTFOLIO_STARTED,function(msg)
		self:debug("Starting a new portfolio...")
		-- Here we should clear the datasets:
		if self._index then
			self._plot.remove = self._index
			self._index = nil
		end
		
		-- self._plot.current = self._index
		-- self._plot.ds_count = 0
	end)

	self:on(Class.EVT_TIMER, function() 
		if self._updatedNeeded then
			self._plot.redraw="yes"
			self._updatedNeeded = false
		end
	end)
end

--[[
Function: addSample

Method used to add a sample
]]
function Class:addSample(x,y)
	if(not self._index) then
		-- Need to create a dataset:
		self:debug("Creating new dataset...")
		self._plot:Begin(0)
		self._index = self._plot:End()
	end

	self._plot:AddSamples(self._index, {x}, {y}, 1)
end

--[[
Function: getPanel

Retrieve the IUP panel for this component
]]
function Class:getPanel()
	return self._panel
end


return Class
