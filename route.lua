local v = "0.2.0"
print ("Running route Script version "..v)
enable_multishell = true
verbosity = 1

if(enable_multishell and multishell) then
	print("Multishell is supported and enabled")
	tab = shell.openTab("startRouting")
	multishell.setTitle(tab, "Router Script")
else
	if not multishell then
		print("Multishell not supported")
	elseif not enable_multishell then
		print("Multishell is disabled")	
	end

	require('router')
	require('modem')
	require('tableUtils')

	local selfRouter = RouterClass(os.getComputerID())
	selfRouter.modems = ModemClass.getAllModems(selfRouter)
	selfRouter:listen()
end