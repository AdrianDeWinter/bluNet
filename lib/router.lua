local v = "0.2.0"
print ("Using Router version "..v)

local verbosity = verbosity or 0

-- get project root from global contxt or use this files location
PROJECT_ROOT = PROJECT_ROOT or ""

require(PROJECT_ROOT..'/lib/modem')
require(PROJECT_ROOT..'/lib/host')
require(PROJECT_ROOT..'/lib/tableUtils')


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
		elseif protocol == "broadcast" then
			self:handleBroadcast(sender, message)
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
	
	local routes = {}
	for i,host in pairs(result) do
		local hostObj = HostClass(host, {self.id})
		if verbosity >= 2 then
			print("Host:\n"..tostring(hostObj).."\n")
		end
		table.insert(routes, hostObj)
	end
	if verbosity >= 2 then
		print("Found "..#routes .. " matching hosts locally, checking remote networks...")
	end
	
	--get nearby routers and repeat the request to them
	local result = {rednet.lookup("router")}
	local routers = {}
	for _,routerId in pairs(result) do
		local router = HostClass(routerId)
		-- check if message has come via a particular router. if so, skip that one
		if not table.contains(message.routers,router) then
			if verbosity >= 2 then
				print("Found Router: "..routerId)
			end
			-- add router to list of routers to query
			table.insert(routers, RouterClass(routerId,{}))
		elseif verbosity >= 2 then
			print("Skipping Router: "..routerId)
		end
	end
	
	-- if other routers were found and not quet queried, pass the query along
	if #routers > 0 then
		if verbosity >= 1 then
			print("Found "..(#routers).." other routers on the network, propagating request...")
		end
		
		-- propagate the rrequest to each router
		for _,router in pairs(routers) do
			if verbosity >= 2 then
				print("Sending DNS Request to Router "..router.id)
			end
			
			rednet.send(router.id, message, "dns_request")
			
			local r, result, p = rednet.receive("dns_response")
			if verbosity >= 2 then
				print("Recieved " .. #result .. " host id's from the remote router "..router.id)
			end
			
			--append the own id to each routers route, and add them to the list of hosts
			result = HostClass.fromTable(result)
			for _,host in pairs(result) do
				table.insert(host.route, self.id)
				table.insert(routes, host)
			end
		end
	end
	
	-- return the found routes to the requester
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
	
	-- check for dangerous nil values and discard if necessary
	if message == nil or message.route == nil or message.target == nil then
		print("Discarding broken packet")
		if verbosity >= 1 then
			print("  Packet was discarded for missing required fields")
		end
		return
	end
	
	-- check that a route table is present
	if type(message.route) ~= "table" then
		print("Discarding broken packet")
		if verbosity >= 1 then
			print("  Packet was discarded for an incorrect data type in route field")
		end
		if verbosity >= 2 then
			print("  Got "..type(message.route).." instead of 'table'")
		end
		return
	end
	
	-- check wether any hops are left
	if #message.route == 0 then
		print("A packet not addressed to this computer has reached TTL")
		return
	
	-- hand off to target host
	elseif #message.route == 1 then
		if verbosity >= 2 then
			print("Last router on route, passing packet to final destination")
		end
		
		--catch broken packets
		if type(message.target) ~= "number" then
			print("Discarding broken packet")
			if verbosity >= 1 then
				print("  Packet was discarded for an incorrect data type in target field")
			end
			if verbosity >= 2 then
				print("  Got "..type(message.target).." instead of 'number'")
			end
			return
		end
		
		if type(message.protocol) ~= "string" and message.protocol ~= nil then
			print("Discarding broken packet")
			if verbosity >= 1 then
				print("  Packet was discarded for an incorrect data type in protocol field")
			end
			if verbosity >= 2 then
				print("  Got "..type(message.target).." instead of 'string' or nil")
			end
			return
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

function RouterClass:handleBroadcast(sender, message)
	local message = message
	
	if verbosity >= 1 then
		print("Handling broadcast from "..sender.id)
	end
	
	--catch broken packets
	if message ~= nil and type(message.protocol) ~= "string" then
		print("Discarding broken packet")
		if verbosity >= 1 then
			print("  Packet was discarded for an incorrect data type in protocol field")
		end
		if verbosity >= 2 then
			print("  Got "..type(message.protocol).." instead of 'string'")
		end
		return
	end
	
	-- create routers list on the message if it does not yet exist
	message.routers = message.routers or {}
	-- break processing if this message was already handled on this router
	if table.contains(message.routers, self.id) then
		if verbosity >= 1 then
			print("Duplicate of previous broadcast message. Won't rebroadcast")
		end
		return
	end
	
	if verbosity >= 1 then
		print("Rebroadcasting packet on "..message.protocol)
	end
	table.insert(message.routers, self.id)
	-- pass to routers
	rednet.broadcast(message, "broadcast")

	--send on to recipients
	rednet.broadcast(message.payload, message.protocol)	
end
