local Type = require("src.types.type")

--- @class Float : Type
local Float = setmetatable({}, { __index = Type })
Float.__index = Float

function Float:formatDefault(value)
	assert(type(value) == "number", self.name .. " default must be a number!")
	return tostring(value)
end

return setmetatable(Type.new("FLOAT"), Float) --[[@as Float]]
