local v = "0.2.0"
print ("Running bluNet api version "..v)

-- get project root from global context or use this files location
PROJECT_ROOT = PROJECT_ROOT or "/"..fs.getDir(debug.getinfo(1).source:sub(2))

require(PROJECT_ROOT.."/lib/host")
require(PROJECT_ROOT.."/lib/overloaded")
require(PROJECT_ROOT.."/lib/router")

local allowNonUniqueTargetHosts = allowNonUniqueTargetHosts or false
local verbosity = verbosity or 0

bluNet = {}

bluNet.DEFAULT_CHANNEL = "bluNet_msg"
bluNet.FILE_TRANSFER_CHANNEL = "bluNet_ft"

local function sendbyHostName(name, msg, protocol)
	if verbosity >= 1 then
		print("Attempting to message "..name.."...")
	end
	if verbosity >= 2 then
		print("Message: "..tostring(msg))
	end
	
	-- determine protocol
	local protocol = protocol or bluNet.DEFAULT_CHANNEL
	
	local success, target = pcall(bluNet.findRoute, protocol, name)
	if success then
		--send message along the shortest route
		rednet.send(target.route[#target.route], {target = target.id, payload = msg, protocol = protocol, route = target.route}, "packet")
	else
		if verbosity >= 1 then
			print("DNS failed. Trying local network...")
		end
	
		--try to send locally
		success, target = pcall(bluNet.findLocally, protocol, name)
		if success then
			rednet.send(target, msg, protocol)
		end
	end
	
	if verbosity >= 2 then
		if success then
			print("Sent")
		else
			print("Target not found")
		end
	end
	return success
end

local function sendbyHostId(id, msg, protocol)
	local protocol = protocol or bluNet.DEFAULT_CHANNEL
	rednet.send(id, msg, protocol)
end

local function broadcast(message, protocol)
	local protocol = protocol or bluNet.DEFAULT_CHANNEL
	rednet.broadcast({payload = message, protocol = protocol}, "broadcast")
end

local function invalidArgs(...)
	local argTypes = ""
	for _,v in ipairs(arg) do
		argTypes = argTypes..type(v)..", "
	end
	argtypes = argTypes:sub(1, -3) -- delete trailing ", "
	print ("Invalid argument types: "..argTypes)
end

function bluNet.startRouter()
	ModemClass.openAllModems()
	local selfRouter = RouterClass(os.getComputerID())
	selfRouter.modems = ModemClass.getAllModems(selfRouter)

	rednet.host("router",("router"..selfRouter.id))
	if verbosity >= 2 then
		print("Running router on computer "..selfRouter.id)
	end
	
	selfRouter:listen()
end

function bluNet.findLocally(protocol, host)
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
				return target[1]
			else
				if verbosity >= 1 then
					print("Target host was not unique. Set allowNonUniqueTargetHosts to true to send anyways")
				end
				error("HostNotUniqueError")
			end
		-- if a unique target host was found, send the message
		else
			if verbosity >= 1 then
				print("Found target on local network")
			end
			return target[1]
		end
	else
		if verbosity >= 1 then
			print("DNS yielded no results. Host can not be reached")
		end
		error("HostNotfoundError")
	end
end

function bluNet.findRoute(protocol, host)
	-- if routers are present and we have not returned yet, start a dns request
	if verbosity >= 1 then
		print("Querying DNS...")
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
		return shortestRoute
	end
end

-- Listens on the provided channel for messages adressed at hostName
-- If no channel is prided, bluNet.DEFAULT_CHANNEL is used.
-- If no host name is provided, listens for all messages sent on that channel
function bluNet.receive(channel, hostName)
	local channel = channel or bluNet.DEFAULT_CHANNEL
	
	rednet.host(channel, hostName)
	
	src, msg, prtcl = rednet.receive(channel)
	
	rednet.unhost(channel)
	
	return msg, src
end

--Transmits the file at path to the host named targetName
function bluNet.sendFile(path, targetName)
	if verbosity > 1 then
		print("Sending file "..path.." to "..targetName)
	end
	if verbosity > 2 then
		print("Opening file...")
	end
	
	local file = fs.open(path, "r")

	if verbosity > 2 then
		print("Reading...")
	end
	
	local content = file.readAll()
	file.close()
	
	if verbosity > 1 then
		print("File read")
	end
	if verbosity > 2 then
		print("Read "..#content.."lines")
	end
	
	sendbyHostName(targetName, {name = fs.getName(path), file = content}, bluNet.FILE_TRANSFER_CHANNEL)
	
	if verbosity > 2 then
		print("Sent")
	end
end

-- Waits for a file transmission
-- The transmitted file is stored into the targetDir directory, or /download if nil is passed
-- The file is stored with the given name, or it's original name if nil is passed
function bluNet.receiveFile(targetDir, name)
	local targetDir = targetDir or "/download"
	-- targetDir must be a directory
	if fs.exists(targetDir) and not fs.isDir(targetDir) then
		error("Path "..targetDir.." is not a directory")
	end
	local name = name or ""
	
	if verbosity >= 1 then
		if not (name == "") then
			print("Expecting to receive file "..name.." into "..targetDir)
		else
			print("Expecting to receive a file into "..targetDir)
		end
	end
	
	-- wait for the file transmission
	local msg = bluNet.receive(bluNet.FILE_TRANSFER_CHANNEL, "PC"..os.getComputerID())
	
	
	if verbosity >= 1 then
		print("Recived file from "..name.." into "..targetDir)
	end
	
	-- check message integrity
	if msg.name == nil or msg.name == "" then
		error("Missing filename in file transfer operation")
	elseif name == "" then
		name = msg.name
		if verbosity >= 2 then
			print("Using original file name since none was supplied")
		end
	end
	
	-- test file collision and build alternative path
	local intendedFullPath = targetDir.."/"..name
	local actualFullPath = intendedFullPath
	local retries = 0
	while fs.exists(actualFullPath) do
		retries = retries + 1
		if verbosity >= 2 then
			print("File "..actualFullPath.." exists, renaming")
		end
		actualFullPath = intendedFullPath..retries
	end
	
	local file = fs.open(actualFullPath, "w")
	file.write(msg.file)
	file.close()
	if verbosity >= 1 then
		print("  Done")
	end
end

-- define overloads to discriminate between host name and host id based transmission
bluNet.send = overloaded()
bluNet.broadCast = overloaded()

bluNet.send.default = invalidArgs
bluNet.broadCast.default = invalidArgs

-- overloads for targeting host ids
function bluNet.send.number.string.string(recipient, message, protocol)
	sendbyHostId(recipient, message, protocol)
end

function bluNet.send.number.string(recipient, message)
	sendbyHostId(recipient, message, protocol)
end

function bluNet.send.number.number.string(recipient, message, protocol)
	sendbyHostId(recipient, message, protocol)
end

function bluNet.send.number.number(recipient, message)
	sendbyHostId(recipient, message, protocol)
end

function bluNet.send.number.table.string(recipient, message, protocol)
	sendbyHostId(recipient, message, protocol)
end

function bluNet.send.number.table(recipient, message)
	sendbyHostId(recipient, message, protocol)
end

function bluNet.send.number.boolean.string(recipient, message, protocol)
	sendbyHostId(recipient, message, protocol)
end

function bluNet.send.number.boolean(recipient, message)
	sendbyHostId(recipient, message, protocol)
end

-- Overloads for targeting host names
function bluNet.send.string.string.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function bluNet.send.string.string(recipient, message)
	sendbyHostName(recipient, message, protocol)
end

function bluNet.send.string.number.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function bluNet.send.string.number(recipient, message)
	sendbyHostName(recipient, message, protocol)
end

function bluNet.send.string.table.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function bluNet.send.string.table(recipient, message)
	sendbyHostName(recipient, message, protocol)
end

function bluNet.send.string.boolean.string(recipient, message, protocol)
	sendbyHostName(recipient, message, protocol)
end

function bluNet.send.string.boolean(recipient, message)
	sendbyHostName(recipient, message, protocol)
end

-- Overloads for targeting protocols
function bluNet.broadCast.string.string(message, protocol)
	broadcast(message, protocol)
end

function bluNet.broadCast.string(message)
	broadcast(message, protocol)
end

function bluNet.broadCast.number.string(message, protocol)
	broadcast(message, protocol)
end

function bluNet.broadCast.number(message)
	broadcast(message, protocol)
end

function bluNet.broadCast.table.string(message, protocol)
	broadcast(message, protocol)
end

function bluNet.broadCast.table(message)
	broadcast(message, protocol)
end

function bluNet.broadCast.boolean.string(message, protocol)
	broadcast(message, protocol)
end

function bluNet.broadCast.boolean(message)
	broadcast(message, protocol)
end