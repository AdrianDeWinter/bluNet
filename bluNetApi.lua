local v = "0.1.0"
print ("Running bluNet api version "..v)
require("host")
require ("overloaded")

local allowNonUniqueTargetHosts = allowNonUniqueTargetHosts or false
local verbosity = verbosity or 2

local function sendbyHostName(name, msg, protocol)
	if verbosity >= 1 then
		print("Attempting to message "..name.."...")
	end
	
	if verbosity >= 2 then
		print("Message: "..msg)
	end
	
	-- try to find the target on the local network
	local target = {rednet.lookup(protocol, host)}
	if verbosity >= 1 then
		print("Recieved lookup Response with "..#target.." entries")
	end
	
	if verbosity >= 2 then
		for _, v in pairs(target) do
			print(v)
		end
	end
	
	-- raise an error if the host does not exist	
	if next(target) ~= nil then
		if #target ~= 1 then	
			-- raise and error if the host is not unique, unless configured otherwise
			if allowNonUniqueTargetHosts then
				if verbosity >= 1 then
					print("Target host was not unique. allowNonUniqueTargetHosts is set to true. Sending message...")
				end
				rednet.send(target[1], msg, protocol)
			else
				if verbosity >= 1 then
					print("Target host was not unique. Set allowNonUniqueTargetHosts to true to send anyways")
				end
				error("HostNotUniqueError")
			end
		-- if a unique target host was found, send the message
		else
			if verbosity >= 1 then
				print("Sending on local network")
			end
			rednet.send(target[1], msg, protocol)
			if verbosity >= 2 then
				print("Sent")
			end
			return
		end
	end

	-- if routers are present and we have not returned yet, start a dns request
	if verbosity >= 1 then
		print("Target not on local network. Querying DNS...")
	end
	
	local routers = {rednet.lookup("router")}

	if next(routers) == nil then
		if verbosity >= 1 then
			print("No routers available. Target can not be reached")
		end
		error("HostNotfoundError")
	else
		if verbosity >= 2 then
			print("Found "..#routers.." Router instances")
			print("Querying router "..routers[1])
		end
		
		rednet.send(routers[1], {protocol = protocol, hostname = name}, "dns_request")
		local _, response,_ = rednet.receive("dns_response", 10)
		if response == nil then
			if verbosity >= 1 then
				print("Router did not respon in time")
			end
			error("RequestTimeoutError")
		end
		if #response == 0 then
			if verbosity >= 1 then
				print("DNS yielded no results. Host can not be reached")
			end
			error("HostNotfoundError")
		end

		-- restore to full HostClass objects
		local hosts = HostClass.fromTable(response)
			if verbosity >= 1 then
				print("DNS yielded "..#hosts.." Results")
			end
		if verbosity >= 2 then
			for _,v in pairs(hosts) do
				print(v)
			end
		end
		--find shortest route
		local shortestRoute = hosts[1]
		for _,host in pairs(hosts) do
			if #host.route < #shortestRoute.route then
				shortestRoute = host
			end
		end
		
		--send message along the shortest route
		rednet.send(shortestRoute.route[#shortestRoute.route], {target = shortestRoute.id, payload = msg, protocol = protocol, route = shortestRoute.route}, "packet")
	end
end


local function sendbyHostId(id, msg, protocol)
	rednet.send(id, msg, protocol)
end

-- define overloads to discriminate between host name and host id based transmission
send = overloaded()

function send.default(...)
	local argTypes = ""
	for _,v in ipairs(arg) do
		argTypes = argTypes..type(v)..", "
	end
	argtypes = argTypes:sub(1, -3) -- delete trailing ", "
	print ("Invalid argument types: "..argTypes)
end

-- overloads for targeting host ids
function send.number.string.string(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.string.nil_val(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.number.string(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.number.nil_val(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.table.string(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.table.nil_val(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.boolean.string(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.boolean.nil_val(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

-- Overloads for targeting host names
function send.string.string.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.string.nil_val(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.number.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.number.nil_val(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.table.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.table.nil_val(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.boolean.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.boolean.nil_val(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

-- Overloads for targeting protocols
function send.nil_val.string.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.nil_val.number.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.nil_val.table.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.nil_val.boolean.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end
