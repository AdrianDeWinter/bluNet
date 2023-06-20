local v = "0.2.0"
verbosity = 2
allowNonuniqueTargetHosts = true
-- get project root from global context or use this files location
PROJECT_ROOT = PROJECT_ROOT or "/"..fs.getDir(fs.getDir(debug.getinfo(1).source:sub(2)))

print ("Running test Script version "..v)
require(PROJECT_ROOT..'/lib/host')
require(PROJECT_ROOT.."/lib/modem")
require(PROJECT_ROOT.."/bluNet")

ModemClass.openAllModems()

router = rednet.lookup("router")
print("Found router "..router)

print("Sending DNS request")
rednet.send(router, {protocol = "test_res", hostname="test_host"}, "dns_request")
print("Awaiting DNS response")

s, response, p = rednet.receive("dns_response")
print("Recieved DNS reponse")

hosts = HostClass.fromTable(response)

for _,host in pairs(hosts) do
	print(host)
end

print("sending test packet")
local target = response[1]
rednet.send(target.route[#target.route], {target = target.id, payload="DNS test successful", protocol="test_res", route=target.route}, "packet")

bluNet.send("test_host", "bluNet test successful", "test_res")

rednet.host("test_channel", "test_pc")
bluNet.send(os.getComputerID(), "Full success!", "test_channel")
local _, msg, _ = rednet.receive("test_channel")
rednet.unhost("test_channel")
print(msg)

ModemClass.closeAllModems()

