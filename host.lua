local v = "0.1.0"
print ("Using Host version "..v)
--stores information about a client, specifically, its id and which modems it is connected to
HostClass = {id=nil, route={}}
function HostClass.__init__(baseClass,id,route)
	id = id or -1
	route = route or {}
	self = {id=id, route=route, hasToString=true}
    setmetatable(self, {__index=HostClass,__tostring=HostClass.toString,__eq=HostClass.equal})
    return self
end
setmetatable(HostClass, {__index=table,__call=HostClass.__init__})
function HostClass:toString()
	ret = "ID: "..self.id
	if #self.route>0 then
		ret = ret.."\nHops:\n"
		for i,hop in pairs(self.route) do
			ret = ret..hop
			if i < #self.route then
				ret = ret ..", "
			end
		end
	end
	return ret
end
function HostClass.equal(host1, host2)
	--test that both object have an id property that is not nil
	local result, retval = pcall(function() return host1.id == host2.id and host1.id ~= nil end)
	return result and retval
end

--takes in a table of host objects and creates new host objects from them (used to restore mthods after transmission over the network)
function HostClass.fromTable(t)
	retval = {}
	for _,host in pairs(t) do
		hostObj = HostClass(host.id, host.route)
		table.insert(retval, hostObj)
	end
	return retval
end