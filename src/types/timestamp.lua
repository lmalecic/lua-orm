local Type = require("src.types.type")

--- @class Timestamp : Type
local Timestamp = setmetatable({}, { __index = Type })
Timestamp.__index = Timestamp

function Timestamp:formatDefault(value)
	if type(value) == "string" then
		return "'" .. value .. "'"
	end
	error("TIMESTAMP default must be a string literal or Column.raw(...)")
end

return setmetatable(Type.new("TIMESTAMP"), Timestamp) --[[@as Timestamp]]
