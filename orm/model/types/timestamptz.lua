local Type = require("orm.model.types.type")
local CurrentTimestamp = require("orm.model.current-timestamp")

--- @class TimestampTz : Type
local TimestampTz = setmetatable({}, { __index = Type })
TimestampTz.__index = TimestampTz
TimestampTz.class = TimestampTz

function TimestampTz.new()
	return setmetatable(Type.new("TIMESTAMPTZ"), TimestampTz) --[[@as TimestampTz]]
end

function TimestampTz:formatDefault(value)
	if type(value) == "string" then
        return "'" .. value .. "'"
    elseif type(value == "table") then
		if value.class == CurrentTimestamp then
			return tostring(CurrentTimestamp)
		end
	end
	error("TIMESTAMPTZ default must be a string literal or Field.raw(...)")
end

return TimestampTz.new()
