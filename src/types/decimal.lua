local Type = require("src.types.type")

--- @class Decimal : Type
--- @field precision number?
--- @field scale number?
local Decimal = setmetatable({}, { __index = Type })
Decimal.__index = Decimal

function Decimal:toSql()
	if self.precision and self.scale then
		return string.format("DECIMAL(%d,%d)", self.precision, self.scale)
	elseif self.precision then
		return string.format("DECIMAL(%d)", self.precision)
	end

	return "DECIMAL"
end

function Decimal:formatDefault(value)
	assert(type(value) == "number", self.name .. " default must be a number!")
	return tostring(value)
end

--- @param precision number?
--- @param scale number?
--- @return Decimal
return function(precision, scale)
	if precision == nil and scale ~= nil then
		error("Parameter scale is not supported without precision parameter!")
	end

	local self = setmetatable(Type.new("DECIMAL"), Decimal) --[[@as Decimal]]
	self.precision = precision
	self.scale = scale

	return self
end
