local v = "0.1.0"
-- get project root from global context or use this files location
PROJECT_ROOT = PROJECT_ROOT or "/"..fs.getDir(fs.getDir(debug.getinfo(1).source:sub(2)))
require(PROJECT_ROOT.."/lib/tableUtils")

local ROUTER_STARTUP_COMMAND = PROJECT_ROOT.."/startupScripts/startRouting -noTab"

if(table.contains(arg, "-noTab")) then
	print ("Using startRouting Script version "..v)
	require(PROJECT_ROOT.."/bluNet")
	bluNet.startRouter()
elseif(multishell) then
	print("Multishell is supported and enabled")
	local tab = shell.openTab(ROUTER_STARTUP_COMMAND)
	multishell.setTitle(tab, "Router Script")
elseif not multishell then
	print("Multishell not supported")
	shell.run(ROUTER_STARTUP_COMMAND)
end