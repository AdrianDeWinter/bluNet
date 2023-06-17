local v = "0.1.0"
print ("Using table utils version "..v)

--injects functions into the table class, after calling this module via require(), any table in the program can use these methods
function table:contains(element)
  for index, value in pairs(self) do
    if value == element then
      return index
    end
  end
  return false
end

function table:removeItem(element)
	for index, value in pairs(self) do
		if value == element then
			self:remove(index)
			return true
		end
	end
	return false
end

function table:toString(depth)
	local depth = depth or 0
	local retval = ""
	local longestKey = 0
	--find longest key in table level
	for key,_ in pairs(self) do
		local length = string.len(tostring(key))
		if length > longestKey then
			longestKey = length
		end
	end
	
	for index,v in pairs(self) do
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