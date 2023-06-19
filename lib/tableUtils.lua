local v = "0.1.0"
print ("Using table utils version "..v)

--add functions to the table class
function table.contains(t, element)
	for index, value in pairs(t) do
		if value == element then
			return index
		end
	end
	return false
end

function table.removeItem(t, element)
	for index, value in pairs(t) do
		if value == element then
			t:remove(index)
			return true
		end
	end
	return false
end

function table.toString(t, depth)
	local depth = depth or 0
	local retval = ""
	local longestKey = 0
	--find longest key in table level
	for key,_ in pairs(t) do
		local length = string.len(tostring(key))
		if length > longestKey then
			longestKey = length
		end
	end
	
	for index,v in pairs(t) do
	retval = retval.."\n "
	--print(retval)
		if type(v) == "table" then
			--process objects that have their own tostring methods
			if v.hasToString==true then
				s = tostring(v)
			else
				s = table.toString(v, depth+1)
			end
			local strings = {}
			for t in s:gmatch("[^\n]+") do
				table.insert(strings, t)
			end
			local start = 1
			for i=start, #strings do
				local indend = ""
				if i > 1 then
					indent = buildIndent(longestKey)
				else
					indent = buildIndent(longestKey, index)
				end
				retval = retval.."\n"..indent..strings[i]
			end
		else
			local indent = buildIndent(longestKey, index)
			retval = retval.."\n"..indent..tostring(v)
		end
	end
	return retval
end

-- copies all key, value pairs into a new table
function table.copy(t)
	local u = {}
	for key, value in pairs(t) do
		u.key = value
	end
	return u
end


-- "upgrades a table. Sets table.toString as it's tostring mrthod, and adds all other methods from this module to the table"
function table.upgrade(t)
	local mt = getmetatable(t) or {}
	mt.__tostring = table.toString
	setmetatable(t, mt)
	t.contains = table.contains
	t.removeItem = table.removeItem
	t.copy = table.copy
end

function buildIndent(length, index)
	local index = index or nil
	length = length + 2
	retval = ""
	if index ~= nil then
		retval = tostring(index)..": "
	end
	for i=1,length-string.len(retval) do
		retval = retval.." "
	end
	return retval
end