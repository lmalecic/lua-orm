local Type = require("src.types.type")

--- @class TimestampTz : Type
local TimestampTz = setmetatable({}, { __index = Type })
TimestampTz.__index = TimestampTz

function TimestampTz:formatDefault(value)
	if type(value) == "string" then
		return "'" .. value .. "'"
	end
	error("TIMESTAMPTZ default must be a string literal or Column.raw(...)")
end

return setmetatable(Type.new("TIMESTAMPTZ"), TimestampTz) --[[@as TimestampTz]]
