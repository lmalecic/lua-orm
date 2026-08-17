local Type = require("orm.model.types.type")

--- @class Float : Type
local Float = setmetatable({}, { __index = Type })
Float.__index = Float
Float.class = Float
Float.super = Type
Float.typeName = "Float"

function Float.new()
	return setmetatable(Type.new("FLOAT"), Float) --[[@as Float]]
end

function Float:formatDefault(value)
    assert(type(value) == "number", self.name .. " default must be a number!")
    return tostring(value)
end

function Float:equals(other)
    if other == nil then
        return false
    end

    if self == other then
        return true
    end

    if getmetatable(self) == getmetatable(other) then
        return true
    end

    return false
end

return Float.new()
