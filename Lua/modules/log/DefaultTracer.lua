local Class = createClass{name="DefaultTracer",bases={"log.LoggerBase"}};

local lm = require "log.LogManager"

for k,v in pairs(Class.levels) do
	Class[k] = function(self,trace,...) 
		lm:log(v,type(trace)=="table" and trace._TRACE_ or trace,self:write(...)); 
	end
	Class[k.."_v"] = function(self,trace,...) 
		if lm:getVerbose() then
			lm:log(v,type(trace)=="table" and trace._TRACE_ or trace,self:write(...)); 
		end
	end
end

local inst = Class()

-- Extend the ObjectBase class:
local ObjectBase = require "base.ObjectBase"

for k,v in pairs(Class.levels) do
	ObjectBase[k] = function(self,msg,...) 
		return Class[k](inst,self,msg,...); end
	ObjectBase[k.."_v"] = function(self,msg,...) 
		return Class[k.."_v"](inst,self,msg,...); end
end

return inst

