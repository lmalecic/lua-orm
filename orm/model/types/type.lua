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

---@param obj any
---@return boolean
function Type.isInstance(obj)
    if type(obj) ~= "table" or type(obj.class) ~= "table" then
        return false
    end
    local class = obj.class
    while class do
        if class == Type then
            return true
        end
        class = class.super
    end
    return false
end

return Type
