local v = "0.1.0"
print ("Using startRouting Script version "..v)

verbosity=1

-- get project root from global context or use this files location
PROJECT_ROOT = PROJECT_ROOT or "/"..fs.getDir(debug.getinfo(1).source:sub(2))

require(PROJECT_ROOT.."/lib/router")
require(PROJECT_ROOT.."/lib/modem")
require(PROJECT_ROOT.."/lib/tableUtils")

local selfRouter = RouterClass(os.getComputerID())
selfRouter.modems = ModemClass.getAllModems(selfRouter)
selfRouter:listen()
