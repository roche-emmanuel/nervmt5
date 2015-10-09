local Class = createClass{name="BasePlot",bases={"base.EventHandler","mt5.Enums"}};

--[[
Class: gui.BasePlot

Simple class used to display a balance on a graph

This class inherits from <base.EventHandler>.
]]

--[=[
--[[
Constructor: BasePlot

Create a new instance of the class.

Parameters:
	 No parameter
]]
function BasePlot(options)
]=]
function Class:initialize(options)
	self._plot = iup.plot{
		--    TITLE = "Plot Test",
    MARGINBOTTOM = 30,
    GRAPHICSMODE = "opengl",
	}

	self._updateNeeded = true
	self._panel = iup.vbox{self._plot,gap=2}

	self._plot.legend = "yes"
	self._indexMap = {}

	self:on("msg_" .. Class.MSGTYPE_PORTFOLIO_STARTED,function(msg)
		self._clearNeeded = true
	end)

	self:on(Class.EVT_TIMER, function() 
		if self._updatedNeeded then
			self._plot.redraw="yes"
			self._updatedNeeded = false
		end
	end)
end

--[[
Function: clearAll

Remove all the datasets
]]
function Class:clearAll()
	self._plot.clear = "yes"
	self._indexMap = {}
end

--[[
Function: addSample

Method used to add a sample
]]
function Class:addSample(x,y,id)
	id = id or "default"

	if self._clearNeeded then
		self:clearAll()
		self._clearNeeded = false
	end

	local index = self._indexMap[id]
	if(not index) then
		-- Need to create a dataset:
		self:debug("Creating new dataset for ",id,"...")
		self._plot:Begin(0)
		index = self._plot:End()
		self._indexMap[id] = index
		self._plot.current = index
		self._plot.ds_name = id
	end

	self._plot:AddSamples(index, {x}, {y}, 1)
end

--[[
Function: getPanel

Retrieve the IUP panel for this component
]]
function Class:getPanel()
	return self._panel
end

return Class
