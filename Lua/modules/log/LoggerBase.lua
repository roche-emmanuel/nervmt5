local Class = createClass{name="LoggerBase",bases={}};

local lm = require "log.LogManager"

local levels = {}
levels.fatal = lm.SEV_FATAL
levels.error = lm.SEV_ERROR
levels.warn = lm.SEV_WARNING
levels.notice = lm.SEV_NOTICE
levels.info = lm.SEV_INFO
levels.debug = lm.SEV_DEBUG

Class.levels = levels

function Class:initialize(options)
	self.indent = 0
	self.indentStr = "   "
	
	self.writtenTables = {}; -- used to ensure each table is written only once in a table hierarchy.
	self.currentLevel = 0
	self.maxLevel = 5
end

function Class:pushIndent()
	self.indent = self.indent+1
end

function Class:popIndent()
	self.indent = math.max(0,self.indent-1)
end

function Class:incrementLevel()
	self.currentLevel = math.min(self.currentLevel+1,self.maxLevel)
	return self.currentLevel~=self.maxLevel; -- return false if we are on the max level.
end

function Class:decrementLevel()
	self.currentLevel = math.max(self.currentLevel-1,0)
end

--- Write a table to the log stream.
function Class:writeTable(t)
	local msg = "" -- we do not add the indent on the first line as this would 
	-- be a duplication of what we already have inthe write function.
	
	local id = tostring(t);
	
	if self.writtenTables[t] then
		msg = id .. " (already written)"
	else
		msg = id .. " {\n"
		
		-- add the table into the set:
		self.writtenTables[t] = true
		
		self:pushIndent()
		if self:incrementLevel() then
			for k,v in pairs(t) do
				msg = msg .. string.rep(self.indentStr,self.indent) .. k .. " = ".. self:writeItem(v) .. ",\n" -- 
			end
			self:decrementLevel()
		else
			msg = msg .. string.rep(self.indentStr,self.indent) .. "(too many levels)";
		end
		self:popIndent()
		msg = msg .. string.rep(self.indentStr,self.indent) .. "}"
		
		--local dbg = require "debugger"
		--dbg:assert(,"writtenTable set is invalid.");
	end
	
	return msg;
end

--- Write a single item as a string.
function Class:writeItem(item)
	if type(item) == "table" then
		-- concatenate table:
		return item.__tostring and tostring(item) or self:writeTable(item)
	else
		-- simple concatenation:
		return tostring(item);
	end
end

--- Write input arguments as a string.
function Class:write(...)
	self.writtenTables={};
	self.currentLevel = 0
	
	local msg = string.rep(self.indentStr,self.indent);
	local num = select('#', ...)
	for i=1,num do
		local v = select(i, ...)
		msg = msg .. (v~=nil and self:writeItem(v) or "<nil>")
	end
	
	return msg;
end

return Class
