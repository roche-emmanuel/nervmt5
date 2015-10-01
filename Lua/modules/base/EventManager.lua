local Class = createClass{name="EventManager",bases={"base.EventEmitter"}};

--[[
Class: base.EventManager

Singleton class used to control events and event listeners

This class inherits from <base.EventEmitter>.
]]

--[=[
--[[
Constructor: EventManager

Create a new instance of the class.
Note that this is a singleton class.

Parameters:
	 No parameter
]]
function EventManager(options)
]=]
function Class:initialize(options)
	self:debug("Building EventManager...")
end

--[[
Function: getListeningList

Return the list of events that are listened for
]]
function Class:getListeningList()
	local list = {}
	for k,v in pairs(self._listeners) do
		if #v > 0 then
			table.insert(list,k)
		end
	end

	return list
end

--[[
Function: getNumListeners

Retrieve the number of listeners for a given eventname
]]
function Class:getNumListeners(ename)
	local list = self._listeners[ename]
	return list and #list or 0
end

return Class()