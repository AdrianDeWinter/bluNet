local v = "0.1.0"
print ("Using startListener Script version "..v)

verbosity=1

-- get project root from global context or use this files location
PROJECT_ROOT = PROJECT_ROOT or "/"..fs.getDir(fs.getDir(debug.getinfo(1).source:sub(2)))

require(PROJECT_ROOT.."/lib/modem")

ModemClass.openAllModems()

while true do
	local src, msg, prtcl = rednet.receive()
	print("From: "..src..", via "..prtcl.."\n  "..msg)
end