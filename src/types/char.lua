local Type = require("src.types.type")

--- @class Char : Type
--- @field length number
local Char = setmetatable({}, { __index = Type })
Char.__index = Char

function Char:toSql()
	return "CHAR(" .. self.length .. ")"
end

function Char:formatDefault(value)
	assert(type(value) == "string", "CHAR default must be a string")
	return "'" .. value:gsub("'", "''") .. "'"
end

--- @param length number
--- @return Char
return function(length)
	local self = setmetatable(Type.new("CHAR"), Char) --[[@as Char]]
	self.length = length or 1
	return self
end
