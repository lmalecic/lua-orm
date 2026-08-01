local Type = require("orm.model.types.type")

--- @class Varchar : Type
--- @field length number
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

--- @param length number
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

return Varchar
