local Type = require("orm.model.types.type")

--- @class Float : Type
local Float = setmetatable({}, { __index = Type })
Float.__index = Float
Float.class = Float

function Float.new()
	return setmetatable(Type.new("FLOAT"), Float) --[[@as Float]]
end

function Float:formatDefault(value)
	assert(type(value) == "number", self.name .. " default must be a number!")
	return tostring(value)
end

return Float.new()
