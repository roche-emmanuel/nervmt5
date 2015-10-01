
unloadModules = function(tt)
  for k,v in pairs(package.loaded) do
    for _,pattern in ipairs(tt) do
      if k:find(pattern) then
        print("Unloading package ",k)
        package.loaded[k] = nil
      end
    end
  end
end

repeat

  -- Clean up any previous mess:
  unloadModules{"gui%.","log%.","base%.","mt5_config"}
  collectgarbage('collect')

  -- global level definition of comment methods:
  createClass = require("base.ClassBuilder")()
  log = require("log.DefaultLogger")
  trace = require("log.DefaultTracer")

  CHECK = function(cond,msg,...)
    if not cond then
      log:error(msg,...)
      log:error("Stack trace: ",debug.traceback())
      error("Stopping because a static assertion error occured.")
    end
  end

  PROTECT = function(func)
    local status, res = pcall(func)
    if not status then
      log:error("Error detected: ",res)
    end
  end

  config_file = "mt5_config"

  local app = require "gui.MT5Control"

until not app:run()


