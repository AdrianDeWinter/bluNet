local v = "0.1.0"
print ("Using startListener Script version "..v)

verbosity=1

-- get project root from global context or use this files location
PROJECT_ROOT = PROJECT_ROOT or "/"..fs.getDir(fs.getDir(debug.getinfo(1).source:sub(2)))

require(PROJECT_ROOT.."/lib/modem")
require(PROJECT_ROOT.."/lib/tableUtils")

ModemClass.openAllModems()
rednet.host("test_res", "test_host")
rednet.host("bluNet_msg", "test_host")
rednet.host("bluNet_ft", "test_host")
while true do
	local src, msg, prtcl = rednet.receive()
	local msg_str = ""
	if type(msg)=="table" then msg_str = table.toString(msg) else msg_str = tostring(msg) end
	print("From: "..src..", via "..prtcl.."\n  "..msg_str)
end