--- @class Type
--- @field name string
--- @field class Type
--- @field typeName string
local Type = {}
Type.__index = Type
Type.class = Type
Type.typeName = "Type"

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

function Type:toGeneratorReferenceString()
    assert(self.typeName ~= Type.typeName, "The base Type class does not support toGeneratorReferenceString() method")
    return self.typeName
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

function Type:equals(other)
    if other == nil then
        return false
    end

    if self == other then
        return true
    end

    if self.name == other.name then
        return true
    end

    return false
end

return Type
