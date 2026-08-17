local Type = require("orm.model.types.type")
local CurrentTimestamp = require("orm.model.expressions.current-timestamp")

--- @class TimestampTz : Type
local TimestampTz = setmetatable({}, { __index = Type })
TimestampTz.__index = TimestampTz
TimestampTz.class = TimestampTz
TimestampTz.super = Type
TimestampTz.typeName = "TimestampTz"

function TimestampTz.new()
	return setmetatable(Type.new("TIMESTAMPTZ"), TimestampTz) --[[@as TimestampTz]]
end

function TimestampTz:formatDefault(value)
    if type(value) == "string" then
        return "'" .. value .. "'"
    elseif type(value) == "table" then
        return value:format()
    end
    error("TIMESTAMPTZ default must be a string literal or Field.raw(...)")
end

function TimestampTz:equals(other)
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

return TimestampTz.new()
