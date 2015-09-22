local Class = createClass{name="MT5Control",bases={"base.Object"}};

require( "iuplua" )
require( "cdlua" )
require( "iupluacontrols" )

local lm = require "log.LogManager"

--[[
Class: gui.MT5Control

Main interface definition for the MT5 Control app.

This class inherits from <base.Object>.
]]

--[=[
--[[
Constructor: MT5Control

Create a new instance of the class.

Parameters:
	 No parameter
]]
function MT5Control(options)
]=]
function Class:initialize(options)
	-- Main Application GUI.
	-- We should add a button line for simple tests:
	local test_btn = iup.button{title = "Test"} --, image=im:getImage("refresh")}

	local line = iup.vbox { test_btn, gap=2, alignment="acenter"}

	local logArea = iup.multiline{expand = "YES", appendnewline="yes", formatting="yes"}

	self:createLogSink(logArea)

	local col = iup.vbox { line, logArea, gap=2 }
	dlg = iup.dialog{col; title="MT5 Control", size="400x200"}
	dlg:show()

	test_btn.action = function()
		self:debug("Should print this line.")
  end
end

--[[
Function: createLogSink

Create the default log sink
]]
function Class:createLogSink(target)
	-- Implement a minimal log sink class here:
	local LogClass = createClass{name="GUILogSink",bases={"log.LogSink"}}

	local levelColors = {
		[lm.SEV_FATAL]="200 0 0",
		[lm.SEV_ERROR]="255 0 0",
		[lm.SEV_WARNING]="255 128 0",
		[lm.SEV_NOTICE]="0 120 0",
		[lm.SEV_INFO]="0 0 120",
	}

	function LogClass:output(level,trace,msg)
		target.addformattag = iup.user { fgcolor = levelColors[level] or "0 0 0" }

		-- We should remove the content if found:
		-- (in W:\Cloud\INSYEN\Projects\VBSSim3\sources\plug_core2\src\plug_common.cpp at line 5)
		-- msg = msg:gsub("%(in .-\\plug_core2\\src\\plug_common%.cpp at line 5%) ","")
		-- msg = msg:gsub("%(in .-\\plug_core2\\src\\plug_common%.cpp at line 9%) ","")
		-- msg = msg:gsub("%(in .-\\plug_core2\\src\\plug_common%.cpp at line 13%) ","")
		-- msg = msg:gsub("%(in .-\\plug_core2\\src\\plug_common%.cpp at line 17%) ","")
		target.append = msg
	end
	
	lm:removeAllSinks()
	
	-- Connect the log sink:
	lm:addSink(LogClass())
end

--[[
Function: run

Main function to run this app.
]]
function Class:run()
	--  Execute the main loop of IUP:
	if (iup.MainLoopLevel()==0) then
	  iup.MainLoop()
	end	

	-- release the log manager:
	lm:release()
end

-- return singleton:
return Class()
