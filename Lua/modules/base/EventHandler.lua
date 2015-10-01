local Class = createClass{name="EventHandler",bases={"base.Object"}};

local evtman = require "base.EventManager"

--[[
Class: base.EventHandler

Base class providing support for event handling.

This class inherits from <base.Object>.
]]

--[=[
--[[
Constructor: EventHandler

Create a new instance of the class.
Parameters:
	 No parameter
]]
function EventHandler(options)
]=]
function Class:initialize(options)
	-- list of callbacks currently connected for this entity:
	self._callbacks = {}
end

--[[
Function: on

Method used to attach an event handler for this object
]]
function Class:on(ename,func)
	self:check(ename,"Invalid event name")
	self:check(func,"Invalid event handler")
	table.insert(self._callbacks,evtman:addListener{ename,func})
end

--[[
Function: off

Method used to detach all the event handlers 
coming from this object for a given event name.
]]
function Class:off(ename)
	self:check(ename,"Invalid event name")
	local num = #self._callbacks
	-- reverse iterations to remove the callbacks object properly:
	for i=num,1,-1 do
		if evtman:removeListener(self._callbacks[i],ename) then
			self._callbacks[i] = nil
		end		
	end
end

--[[
Function: removeAllListeners

Method called to remove all the listeners created for this object
]]
function Class:removeAllListeners()
	-- Clear all the connected callbacks:
	for _,cb in ipairs(self._callbacks) do
		evtman:removeListener(cb)
	end
	self._callbacks = {}	
end

return Class