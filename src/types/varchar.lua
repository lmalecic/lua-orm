local Type = require("src.types.type")

--- @class Varchar : Type
--- @field length number
local Varchar = setmetatable({}, { __index = Type })
Varchar.__index = Varchar

function Varchar:toSql()
	return self.length and ("VARCHAR(" .. self.length .. ")") or "VARCHAR"
end

function Varchar:formatDefault(value)
	assert(type(value) == "string", "VARCHAR default must be a string")
	return "'" .. value:gsub("'", "''") .. "'"
end

--- @param length number
--- @return Varchar
return function(length)
	local self = setmetatable(Type.new("VARCHAR"), Varchar) --[[@as Varchar]]
	self.length = length
	return self
end
