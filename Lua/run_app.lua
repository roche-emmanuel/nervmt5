local args = {...}
local appfile = args[1]

-- print('Running app file '.. appfile)
-- 
-- Retrieve the local path to be able to load vstruct:
local scriptFile = debug.getinfo(1).short_src
-- print("Scritpfile: ",scriptFile)

-- print("Getting path...")
getPath=function(str,sep)
    sep=sep or'\\'
    return str:match("(.*"..sep..")")
end

local path = getPath(scriptFile)
-- print("Using path: ",path)

-- print("OS: ", jit.os)
-- print("arch: ", jit.arch)

local flavor=""
if jit.os=="Windows" and jit.arch=="x64" then
	flavor="win64"
else
	error("Unsupported OS/arch: ".. jit.os .."/".. jit.arch)
end

root_path = path
-- print("Root path: ", root_path)

package.path = path.."?.lua;"..path.."?/init.lua;"..path.."modules/?.lua;"..path.."packages/?.lua;"..package.path
package.cpath = path.."bin/"..flavor.."/modules/?.dll;".. path.."bin/"..flavor.."/modules/?51.dll;" ..package.cpath

-- if the appfile contains a final .lua extension then we remove it:
appfile = appfile:gsub("%.lua$","")

print("Loading lua file: ", appfile)
require(appfile)

print("Done.")

