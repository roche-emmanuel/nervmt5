local Class = createClass{name="DefaultLogger",bases={"log.LoggerBase"}};

local lm = require "log.LogManager"
require "log.StdLogger"

for k,v in pairs(Class.levels) do
	Class[k] = function(self,...) 
		lm:log(v,nil,self:write(...)); 
	end
	Class[k.."_v"] = function(self,...) 
		if lm:getVerbose() then
			lm:log(v,nil,self:write(...)); 
		end
	end
end

return Class()