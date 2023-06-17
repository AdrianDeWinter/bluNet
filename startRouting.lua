local v = "0.1.0"
print ("Using startRouting Script version "..v)

verbosity=1

require('router')
require('modem')
require('tableUtils')

local selfRouter = RouterClass(os.getComputerID())
selfRouter.modems = ModemClass.getAllModems(selfRouter)
selfRouter:listen()