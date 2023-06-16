local v = "0.1.0"
print ("Using Router version "..v)
require('modem')
require('host')
require('tableUtils')

local verbosity = verbosity or 2

--stores information about a router, specifically, which other routers and hosts are accessible through it
RouterClass = {id=nil,modems={}}
function RouterClass.__init__(baseClass, id, modems)
	id = id or -1
	modems = modems or {}
    self = {id=id, modems=modems, hasToString=true}
    setmetatable(self, {__index=RouterClass,__tostring=RouterClass.toString,__eq=RouterClass.equal})
    return self
end
setmetatable(RouterClass, {__index=table,__call=RouterClass.__init__})

function RouterClass:toString()
	ret = "ID: "..self.id.."\nModems:\n"
	for i,modem in pairs(self.modems) do
		ret = ret..tostring(modem)
		if i < #self.modems then
			ret = ret .."\n"
		end
	end
	return ret
end

function RouterClass.equal(host1, host2)
	--test that both objects have a router property to distinguish routers from hosts
	if not pcall(host1.modems ~= nil) and pcall(host2.modems ~= nil) then
		return false
	end
	--test whether both router objects refer to the same router id
	local result, retval = pcall(function() return host1.id == host2.id and host1.id ~= nil end)
	return result and retval
end

--takes in a table of host objects and creates new host objects from them (used to restore class methods after transmission over the network)
function RouterClass.fromTable(t)
retval = {}
	for _,router in pairs(t) do
		table.insert(retval,RouterClass(router.id))
	end
	return retval
end

--listens for messages
function RouterClass:listen()
	ModemClass.openAllModems(self.modems)
	rednet.host("router",("router"..self.id))
	if verbosity >= 2 then
		print("Running router on computer "..self.id)
	end
	while true do
		print("Listening...")
		local sender, message, protocol = rednet.receive()
		sender = HostClass(sender)
		print("Recieved message")
		--recieved dns lookup request from a client
		if protocol == "dns_request" then
			self:handleDnsRequest(sender, message)
		elseif protocol == "packet" then
			self:handleTransmission(sender, message)
		else
			print("From "..sender.id.." via "..(protocol or "any")..":")
			if protocol == "dns" then
				print("Request for "..message.sProtocol)
			else
				print(message)
			end
		end
	end
end

function RouterClass:handleDnsRequest(sender, message)
	message.routers = HostClass.fromTable(message.routers)
	table.insert(message.routers, HostClass(self.id))
	
	local printString = "Received DNS request from " .. sender.id..", looking for \"" .. message.protocol .. "\""
	if message.hostname ~= nil then
		printString = printString.." running on \""..message.hostname.."\""
	end
	print(printString)
	
	--send a dns lookup into all connected networks
	local result = {rednet.lookup(message.protocol, message.hostname)}
	
	--see if the requester has ended up in the list. if so, remove them
	if verbosity >= 2 then
		print("Local Hosts:")
	end
	
	local routes = {}
	for i,host in pairs (result) do
		if host ~= sender.id then
			local hostObj = HostClass(host, {self.id})
			if verbosity >= 2 then
				print("Host:\n"..tostring(hostObj).."\n")
			end
			table.insert(routes, hostObj)
		end
	end
	if verbosity >= 2 then
		print("Found "..#routes .. " matching hosts locally, checking remote networks...")
	end
	
	--get nearby routers and repeat the request to them
	local result = {rednet.lookup("router")}
	local routers = {}
	for _,routerId in pairs(result) do
		router = HostClass(routerId)
		if not table.contains(message.routers,router) then
			if verbosity >= 2 then
				print("Found Router:\n  "..tostring(router))
			end
			table.insert(routers, RouterClass(routerId,{}))
		elseif verbosity >= 2 then
			print("Skipping Router:\n  "..tostring(router))
		end
	end
	
	if #routers > 0 then
		if verbosity >= 1 then
			print("Found "..(#routers).." other routers on the network, propagating request...")
		end
		
		for _,router in pairs(routers) do
			--send dns requests to all routers in range except self and the requester
			if verbosity >= 2 then
				print("Sending DNS Request to Router "..router.id)
			end
			
			rednet.send(router.id, message, "dns_request")
			
			local r, result, p = rednet.receive("dns_response")
			if verbosity >= 2 then
				print("Recieved " .. #result .. " host id's from the remote router "..router.id)
			end
			
			--append the own id to each hosts route, and add them to the list of hosts
			result = HostClass.fromTable(result)
			for _,host in pairs(result) do
				table.insert(host.route, self.id)
				table.insert(routes, host)
			end
		end
	end
	--find duplicate routes
	local duplicates_exist = true
	while duplicates_exist do
		local duplicate_found = false
		for i, route in pairs(routes) do
			for j=i+1,#routes do
				r2 = routes[j]
				if route==r2 then
					duplicate_found = true
					if #route.route > #r2.route then
						table.remove(routes, i)
					else
						table.remove(routes, j)
					end
				end
				if duplicate_found then break end
			end
			if duplicate_found then break end
		end
		duplicates_exist = duplicate_found
	end
	
	print ("Returning a total of "..#routes.." host id's to the requester")			
	if verbosity >= 2 then
		for i,route in pairs(routes) do
			print("Host:\n"..tostring(route))
		end
	end
	rednet.send(sender.id, routes, "dns_response")
end

function RouterClass:handleTransmission(sender, message)
	if verbosity >= 1 then 
		print("Handling packet from "..sender.id)
	end
	if #message.route == 0 then
		print("A packet not addressed to this computer has reached TTL")
		return
	elseif #message.route == 1 then
		if verbosity >= 2 then
			print("Last router on route, passing packet to final destination")
		end
		--send on to recipient
		rednet.send(message.target, message.payload, message.protocol)
	else
		--route along
		table.remove(message.route)
		local nextHop = message.route[#message.route]
		if verbosity >= 2 then
			print("Not last router on route, passing packet to router "..nextHop)
		end
		rednet.send(nextHop, message, "packet")
	end
end