local v = "0.1.0"
verbosity = 2
allowNonuniqueTargetHosts = true
-- get project root from global context or use this files location
PROJECT_ROOT = PROJECT_ROOT or "/"..fs.getDir(debug.getinfo(1).source:sub(2))

print ("Running file transfer test Script version "..v)
require(PROJECT_ROOT..'/lib/host')
require(PROJECT_ROOT.."/lib/modem")
require(PROJECT_ROOT.."/bluNet")

ModemClass.openAllModems()

bluNet.sendFile("/test.lua", "test_host")

ModemClass.closeAllModems()
