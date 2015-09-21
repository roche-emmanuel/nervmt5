local Class = createClass{name="MT5Control",bases={"base.Object"}};

require( "iuplua" )

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
	local lbl = iup.label {title="Current outputs:"}
	local text = iup.multiline{expand = "YES", appendnewline="no", formatting="yes"}
	local col = iup.vbox { lbl, text, gap=2 }

	dlg = iup.dialog{col; title="MT5 Control", size="400x200"}
	dlg:show()

	local log = function(msg)
	  text.append = msg .. "\n";
	end
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
end

-- return singleton:
return Class()
