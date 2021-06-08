local v = "0.1.0"
print ("Using route Script version "..v)
enable_multishell = true
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
	shell.run("startRouting")
end