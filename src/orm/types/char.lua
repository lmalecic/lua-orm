local Type = require("orm.types.type")

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

return Char
