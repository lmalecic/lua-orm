local Type = require("orm.metadata.types.type")

--- @class Int : Type
local Int = setmetatable({}, { __index = Type })
Int.__index = Int
Int.class = Int

Int.MIN = -2 ^ 31
Int.MAX = 2 ^ 31 - 1

function Int.new()
    return setmetatable(Type.new("INT"), Int) --[[@as Int]]
end

function Int:supportsAutoIncrement()
	return true
end

function Int:formatDefault(value)
	assert(type(value) == "number", "INT default must be a number!")
	assert(value >= Int.MIN and value <= Int.MAX,
		string.format("INT default %d out of range [%d, %d]!", value, Int.MIN, Int.MAX))
	return tostring(math.floor(value))
end

return Int.new()
