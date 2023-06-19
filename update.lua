local INSTALL_DIR = (arg[1] or "").."/bluNet"
print("Installing into "..INSTALL_DIR)
if(fs.exists(INSTALL_DIR)) then
	fs.delete(INSTALL_DIR)
end
fs.copy(fs.getDir(debug.getinfo(1).source:sub(2)), INSTALL_DIR)
print("Update completed")