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
	self._plot.axs_yautomin = "no" 
	self._plot.axs_yautomax = "no" 

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
	self._timeOffset = nil
	self._ymin = nil
	self._ymax = nil
end

--[[
Function: addTimedSample

Method to add a timed sample into the plot
]]
function Class:addTimedSample(timetag,y,id)
	-- convert the timetag into a time value:
	local x = os.time(timetag);
	if not self._timeOffset then
		self._timeOffset = x
	end
	x = x - self._timeOffset
	-- self:debug("Adding sample at time value: ",x)
	self:addSample(x,y,id)
end

--[[
Function: updateYRange

Method called to update the range of the display on the y axis
]]
function Class:updateYRange(mini,maxi)
	if self._ymin~=mini or self._ymax~=maxi then
		self._ymin = mini
		self._ymax = maxi

		if self._ymin == self._ymax then
			self._plot.axs_ymin = self._ymin - 3.0
			self._plot.axs_ymax = self._ymax + 3.0
		else
			local range = self._ymax - self._ymin
			range = math.max(range,3.0)

			mini = self._ymin - range*0.05
			maxi = self._ymax + range*0.05

			self._plot.axs_ymin = mini
			self._plot.axs_ymax = maxi
			self:debug("Updating display range to: [",mini,", ",maxi,"]")
		end
	end
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

	local ymin = self._ymin and math.min(self._ymin,y) or y
	local ymax = self._ymax and math.max(self._ymax,y) or y
	self:updateYRange(ymin,ymax)

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
