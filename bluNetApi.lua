local v = "0.1.0"
print ("Running bluNet api version "..v)
require("modem")
require("host")
require ("overloaded")


local allowNonUniqueTargetHosts = allowNonUniqueTargetHosts or false
local verbositiy = verbositiy or 0

local function sendbyHostName(name, msg, protocol)
	-- find routers
	local routers = {rednet.lookup("router")}
	-- if no routers are present, attempt to transmit in te local network
	if next(routers) == nil then
		local target = {rednet.lookup(protocol, host)}
		-- raise an error if the host does not exist
		if next(target) == nil then
			error("HostNotFoundError")
		else if #target ~= 1 then
		-- raise and error if the host is not unique, unless configured otherwise
			if allowNonUniqueTargetHosts then
				rednet.send(target[1], msg, protocol)
			else
				error("HostNotUniqueError")
			end
		end
	-- if routers are present, start a dns request
	else
		rednet.send(routers[1], {protocol = protocol, hostname = name}, "dns_request")
		_, local response,_ = rednet.receive("dns_response", 5)
		if response == nil then
			error("RequestTimeoutError")
		end
		if #response == 0 then
			error("HostNotfoundError")
		end

		-- restore to full HostClass ojects
		local hosts = HostClass.fromTable(response)
		
		--find shortest route
		local shortestRoute = hosts[0].route
		for host in pairs(hosts) do
			if #host.route < #shortestRoute then
				local shortestRoute = host
			end
		end
		
		--send message along the shortest route
		rednet.send(shortestRoute.route[#shortestRoute.route], {target = name, message = msg, protocol = protocol}
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
		local argTypes = argTypes..type(v)..", "
	end
	local artypes = argTypes:sub(1, -3) -- delete trailing ", "
	print ("Invalid argument types: "..argTypes)
end

function send.number.string.string(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.string.nil(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.number.string(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.number.nil(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.table.string(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.table.nil(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.boolean.string(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

function send.number.boolean.nil(recipient, message, protocol)
	sendbyHostid(recipient, message, protocol)
end

local function sendbyHostId(id, msg, protocol)

end

function send.string.string.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.string.nil(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.number.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.number.nil(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.table.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.table.nil(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.boolean.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function send.string.boolean.nil(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end
