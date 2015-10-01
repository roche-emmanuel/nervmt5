local Class = createClass{name="EventEmitter",bases="base.Object"};

local utils = require "mt5.utils"
local clearTable = utils.clearTable
local rmSet = utils.removeFromSet
local remove = table.remove

--[[
Class: base.EventEmitter

Implement a simple event handling mechanism.

This class inherits from <base.Object>.
]]

function Class:new(options)
	self._listeners = {}
	self._markedForRemoval = {}
	self._results = {}
end

--[=[
--[[
Constructor: EventHandler

Create a new instance of the class.
]]
function EventHandler(options)
]=]
function Class:initialize(options)

end

--[[
Function: addListener

Add a new listener function to this event handler.

Parameters:
	desc.name or desc[1] - The name of the event to assign this new listener to.
	desc.func or desc[2] - The function to be assigned as listener.
	desc.once - (optional) If true, consider this function as a one shot listener (eg. will only be executed once when triggered,
and then be removed from the listener list).
  
Returns:
	The function passed as argument.
]]
function Class:addListener(desc)
	local ename = desc.name or desc[1]
	local func = desc.func or desc[2]

	self:check(ename,"Invalid event name in addListener.")
	self:check(func,"Invalid function in addListener.")
	

	if type(ename)=="table" then
		-- listed event handlers:
		local list = ename
		for _,ename in ipairs(list) do
			desc[1]=ename
			self:addListener(desc)
		end
		return func
	end

		
	-- check if this is a one shot function:
	local once = desc.once or false
	
	-- retrieve the list of listener for the given event:
	self._listeners[ename] = self._listeners[ename] or {}
	local list = self._listeners[ename]
	
	-- check if we should push the listener in front of the list or at the back
	local front = desc.front or false
	
	if front then
		table.insert(list,1,{func,once})
	else
		table.insert(list,{func,once})
	end	
		
	return func
end

--[[
Function: addListenerOnce

This method is a facade for <addListener> that will simply
force the one shot state.
]]
function Class:addListenerOnce(desc)
	desc.once = true
	return self:addListener(desc)
end

--[[
Function: removeListener

Remove a listener from a given event.

Parameters:
	func - The listener function to be removed.
	ename - (Optional) The even name to remove this listener from. If missing
all the currently available events will be checked and the function will be removed from
each of them.
  markForRemoval - (Optional) When specified the callback is not removed directly, but instead
marked for removal for the execution system. This is needed for a callback to be able to remove itself
properly.

Returns:
  True if a callback was indeed removed.
]]
function Class:removeListener(func,ename,markforRemoval)
	self:check(func,"Invalid callback object.")
	
	if ename then
		local list = self._listeners[ename]
		if not list then
			return false-- nothing to do.
		end

		for i=#list,1,-1 do
			if list[i][1] == func then
				if markForRemoval then
					list[i][2] = true
				else
					remove(list,i)
					return true
				end
			end
		end

		return false
	end
	
	-- no event name is provided so try to remove the handler from all lists:
	for ename,list in pairs(self._listeners) do
		self:removeListener(func,ename,markforRemoval)
	end
end

--[[
Function: removeAllListeners

Remove all the listeners for a given event

Parameters:
	ename - The name of the event to remove all the listeners from. If missing
then all the listeners for all events are removed.
]]
function Class:removeAllListeners(ename)
	if ename then
		local t = self._listeners[ename]
		if t then
			clearTable(t)
		end
	else
		clearTable(self._listeners)
	end
end

--[[
Function: fireEvent

Fire an event and call all the attached listeners.

Parameters:
	ename - The name of the event to fire.
	... - optional arguments passed to the listeners.
  
Returns:
	An optional <std.Vector> containing the results from all the called listener or nil.
]]
function Class:fireEvent(ename,...)
	self:check(type(ename)=="string","Invalid event name ",ename)
	
	local list = self._listeners[ename]

	if not list then
		return; -- nothing to do.
	end

	-- add support for result retrieval.
	-- Since we execute multiple listener, we have to gather multiple results.
	-- and let the caller decide what to do with them.
	clearTable(self._results)
	-- local status -- needed for secured call version.
	
	for i=1,#list do
		local cb = list[i]

		--if cb._name then
		--	self:info("Calling cb: ",cb._name)
		--end
		
		-- call the callback:
		--cb{handler=self,event=ename,args={...}};
		local res = cb[1](...);
		
		-- Secured call version:
		-- status, res = pcall(cb[1],...);
		-- if not status then
			-- self:throw("Error occured in event handler:", res)
		-- end
		
		if res~=nil then
			-- need to store this result:
			self._results[#self._results+1] = res
		end
		
		if cb[2] then
			self._markedForRemoval[#self._markedForRemoval+1] = cb
		end
	end
	
	-- clear the once methods:
	local t = self._markedForRemoval
	for i=#t,1,-1 do
		rmSet(list,t[i])
		remove(t,i)
	end
	
	return self._results -- this may be nil or a vector of values.
end

return Class


