local Type = require("orm.model.types.type")

--- @class Varchar : Type
--- @field length number?
local Varchar = setmetatable({}, {
    __index = Type,

    --- @param length number
    --- @return Varchar
    __call = function(self, length)
    	return self.new(length)
    end
})
Varchar.__index = Varchar
Varchar.class = Varchar
Varchar.super = Type
Varchar.typeName = "Varchar"

--- @param length number?
--- @return Varchar
function Varchar.new(length)
	local self = setmetatable(Type.new("VARCHAR"), Varchar) --[[@as Varchar]]
	self.length = length
	return self
end

function Varchar:toSql()
	return self.length and ("VARCHAR(" .. self.length .. ")") or "VARCHAR"
end

function Varchar:formatDefault(value)
    assert(type(value) == "string", "VARCHAR default must be a string")
    return "'" .. value:gsub("'", "''") .. "'"
end

function Varchar:toGeneratorReferenceString()
    if self.length then
        return ("%s(%d)"):format(self.typeName, self.length)
    end
    return ("%s()"):format(self.typeName)
end

function Varchar:equals(other)
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

return Varchar
