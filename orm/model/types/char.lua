local Type = require("orm.model.types.type")

--- @class Char : Type
--- @field length number
local Char = setmetatable({}, {
    __index = Type,

    --- @param length number
    --- @return Char
    __call = function(self, length)
    	return self.new(length)
    end
})
Char.__index = Char
Char.class = Char
Char.super = Type
Char.typeName = "Char"

--- @param length number
--- @return Char
function Char.new(length)
	local self = setmetatable(Type.new("CHAR"), Char) --[[@as Char]]
	self.length = length or 1
	return self
end

function Char:toSql()
	return "CHAR(" .. self.length .. ")"
end

function Char:formatDefault(value)
    assert(type(value) == "string", "CHAR default must be a string")

    return "'" .. value:gsub("'", "''") .. "'"
end

function Char:toGeneratorReferenceString()
    if self.length == 1 then
        return ("%s()"):format(self.typeName)
    end
    return ("%s(%d)"):format(self.typeName, self.length)
end

function Char:equals(other)
    if other == nil then
        return false
    end

    if self == other then
        return true
    end

    if getmetatable(self) == getmetatable(other) and self.length == other.length then
        return true
    end

    return false
end

return Char
