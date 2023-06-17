local v = "0.1.0"
print ("Using Modem version "..v)

local verbosity = verbosity or 0

ModemClass = {side="", parent={}}
function ModemClass.__init__(baseClass, side, parent)
	side = side or ""
	parent = parent or {}
    self = {side=side, parent=parent, hasToString=true}
    setmetatable(self, {__index=ModemClass,__tostring=ModemClass.toString,__eq=ModemClass.equal})
    return self
end
setmetatable(ModemClass, {__index=table,__call=ModemClass.__init__})
function ModemClass:toString()
	s = "Modem:\n"
	s = s.."  Side: "..self.side.."\n"
	s = s.."  Open: "..tostring(self:isOpen())
	return s
end
function ModemClass.equal(m1, m2)
	--test that both object have a side property that is not nil
	local result, retval = pcall(function() return m1.side == m2.side and m1.side ~= nil end)
	return result and retval
end
function ModemClass:open()
    rednet.open(self.side)
end
function ModemClass:close()
    rednet.close(self.side)
end
function ModemClass:receive(timeout, protocols)
	self:open()
    from, what, how = rednet.receive(protocols, timeout)
	self:close()
	return from, what, how
end
function ModemClass:broadcast(message, protocol)
	self:open()
    rednet.broadcast(message, protocol)
	self:close()
end
function ModemClass:send(target, message, protocol)
	self:open()
    rednet.send(target.id, message, protocol)
	self:close()
end
function ModemClass:ping(host)
	self:send(host.id, nil, "ping")
    sender = rednet.receive("ping", 1)
	self:close()
	if sender == host.id then
		return true
	else
		return false
	end
end
function ModemClass.getAllModems(selfRouter)
	local peripherals = peripheral.getNames()
	local modems = {}
	if verbosity >= 1 then
		print("gathering modems from peripherals")
	end
	for _,peri in pairs(peripherals) do
		if peripheral.getType(peri) == "modem" then
			local newModem = ModemClass(peri, selfRouter)
			if verbosity >= 2 then
				print("found modem on the "..newModem.side)
			end
			modems[#modems + 1] = newModem
		end
	end
	if verbosity >= 1 then
		print("found "..#peripherals.." devices, "..#modems.." of which are modems")
	end
	return modems
end
function ModemClass.openAllModems(modems)
	local modems = modems or ModemClass.getAllModems()
	if verbosity >= 1 then
		print("opening modems")
	end
	for _,modem in pairs(modems) do
		if verbosity >= 2 then
			print ("opening modem: "..modem.side)
		end
		modem:open()
	end
end
function ModemClass.closeAllModems(modems)
	local modems = modems or ModemClass.getAllModems()
	if verbosity >= 1 then
		print("closing modems")
	end
	for _,modem in pairs(modems) do
		if verbosity >= 2 then
			print ("closing modem: "..modem.side)
		end
		modem:close()
	end
end
function ModemClass:isOpen()
	return rednet.isOpen(self.side)
end
--takes in a table of modem objects and creates new modem objects from them (used to restore mthods after transmission over the network)
function ModemClass.fromTable(t)
retval = {}
	for _,modem in pairs(t) do
		table.insert(retval,ModemClass(modem.side, RouterClass(modem.parent.id)))
	end
	return retval
end