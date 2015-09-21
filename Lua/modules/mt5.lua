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

config_file = "mt5_config"

local app = require "gui.MT5Control"

app:run()

-- require( "iuplua" )

-- local lbl = iup.label {title="Current outputs:"}
-- local text = iup.multiline{expand = "YES", appendnewline="no", formatting="yes"}
-- local col = iup.vbox { lbl, text, gap=2 }

-- dlg = iup.dialog{col; title="MT5 Control", size="400x200"}
-- dlg:show()

-- local log = function(msg)
--   text.append = msg .. "\n";
-- end

-- --  Execute the main loop of IUP:
-- if (iup.MainLoopLevel()==0) then
--   iup.MainLoop()
-- end

-- local res
-- while (true) do
--   res = iup.LoopStep();
--   if res == iup.CLOSE then
--     iup.ExitLoop();
--     break;
--   end
-- end
