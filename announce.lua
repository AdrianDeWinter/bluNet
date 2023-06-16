local v = "0.1.0"
print ("Running announce Script version "..v)
require('router')
require('modem')

verbose=0

ModemClass.openAllModems()
service = "test"
hostname = "test_pc"..os.getComputerID()
rednet.host(service, hostname)

print("Hosting "..service.." as "..hostname)

rednet.unhost(service)
