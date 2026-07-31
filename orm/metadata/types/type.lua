--- @class Type
--- @field name string
--- @field class Type
local Type = {}
Type.__index = Type
Type.class = Type

--- @param name string
--- @return Type
function Type.new(name)
	local self = setmetatable({}, Type)
	self.name = name
	return self
end

function Type:toSql()
	return self.name
end

--- @return boolean
function Type:supportsAutoIncrement()
	return false
end

--- @param value any
--- @return string
function Type:formatDefault(value)
	error(self.name .. " does not support default values")
end

return Type
