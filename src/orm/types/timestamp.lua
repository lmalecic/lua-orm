local Type = require("orm.types.type")
local CurrentTimestamp = require("orm.current-timestamp")

--- @class Timestamp : Type
local Timestamp = setmetatable({}, { __index = Type })
Timestamp.__index = Timestamp
Timestamp.class = Timestamp

function Timestamp.new()
	return setmetatable(Type.new("TIMESTAMP"), Timestamp) --[[@as Timestamp]]
end

function Timestamp:formatDefault(value)
	if type(value) == "string" then
        return "'" .. value .. "'"
	elseif type(value == "table") then
		if value.class == CurrentTimestamp then
			return tostring(CurrentTimestamp)
		end
	end
	error("TIMESTAMP default must be a string literal, a CurrentTimestamp instance or Field.raw(...)")
end

return Timestamp.new()
