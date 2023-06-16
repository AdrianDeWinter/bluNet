local v = "0.1.0"
print ("Using startRouting Script version "..v)
require('router')
require('modem')
require('tableUtils')

verbose=2
selfRouter = RouterClass(os.getComputerID())
selfRouter.modems = ModemClass.getAllModems(selfRouter)
selfRouter:listen()