local v = "0.1.0"
print ("Using route Script version "..v)

-- get project root from global context or use this files location
PROJECT_ROOT = PROJECT_ROOT or "/"..fs.getDir(debug.getinfo(1).source:sub(2))

local ROUTER_STARTUP_SCRIPT_LOCATION = PROJECT_ROOT.."/startRouting.lua"

enable_multishell = true
if(enable_multishell and multishell) then
	print("Multishell is supported and enabled")
	tab = shell.openTab(ROUTER_STARTUP_SCRIPT_LOCATION)
	multishell.setTitle(tab, "Router Script")
else
	if not multishell then
		print("Multishell not supported")
	elseif not enable_multishell then
		print("Multishell is disabled")	
	end
	shell.run(ROUTER_STARTUP_SCRIPT_LOCATION)
end