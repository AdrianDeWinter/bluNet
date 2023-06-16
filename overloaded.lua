-- copied from: http://lua-users.org/wiki/OverloadedFunctions

overloaded()
	local fns = {}
	local mt = {}

	local function oerror()
		return error("Invalid argument types to overloaded function")
	end

	function mt:__call(...)
		local arg = {...}
		local default = self.default
		
		local signature = {}
		for i,arg in ipairs {...} do
			signature[i] = type(arg)
		end
		
		signature = table.concat(signature, ",")
		
		return (fns[signature] or self.default)(...)
	end

	function mt:__index(key)
		local signature = {}
		local function __newindex(self, key, value)
			print(key, type(key), value, type(value))
			signature[#signature+1] = key
			fns[table.concat(signature, ",")] = value
			print("bind", table.concat(signature, ", "))
		end
		local function __index(self, key)
			print("I", key, type(key))
			signature[#signature+1] = key
			return setmetatable({}, { __index = __index, __newindex = __newindex })
		end
		return __index(self, key)
	end

	function mt:__newindex(key, value)
		fns[key] = value
	end

	return setmetatable({ default = oerror }, mt)
end
