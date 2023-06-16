local v = "0.1.0"
print ("Using startRouting Script version "..v)
verbosity=2

require('router')
require('modem')
require('tableUtils')

selfRouter = RouterClass(os.getComputerID())
selfRouter.modems = ModemClass.getAllModems(selfRouter)
selfRouter:listen()