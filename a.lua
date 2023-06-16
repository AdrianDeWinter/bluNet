local v = "0.1.0"
print ("Running test Script version "..v)
require('host')


router = rednet.lookup("router")
print("Found router "..router)

print("Sending DNS request")
rednet.send(router, {protocol = "test", hostname="pda"}, "dns_request")
print("Awaiting DNS response")

s, response, p = rednet.receive("dns_response")
print("Recieved DNS reponse")

hosts = HostClass.fromTable(response)

for _,host in pairs(hosts) do
	print(host)
end

print("sending test packet")
local target = response[1]
rednet.send(target.route[#target.route], {target = target.id, payload="test erfolg", protocol="test_res", route=target.route}, "packet")

ModemClass.closeAllModems()