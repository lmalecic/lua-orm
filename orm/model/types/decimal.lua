local Type = require("orm.model.types.type")

--- @class Decimal : Type
--- @field precision number?
--- @field scale number?
local Decimal = setmetatable({}, {
    __index = Type,

	--- @param precision number?
	--- @param scale number?
	--- @return Decimal
    __call = function(self, precision, scale)
        return self.new(precision, scale)
    end,
})
Decimal.__index = Decimal
Decimal.class = Decimal
Decimal.super = Type
Decimal.typeName = "Decimal"

--- @param precision number?
--- @param scale number?
--- @return Decimal
function Decimal.new(precision, scale)
	if precision == nil and scale ~= nil then
		error("Parameter scale is not supported without precision parameter!")
	end

	local self = setmetatable(Type.new("DECIMAL"), Decimal) --[[@as Decimal]]
	self.precision = precision
	self.scale = scale

	return self
end

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

function Decimal:toGeneratorReferenceString()
    if self.precision and self.scale then
        return ("%s(%d, %d)"):format(self.typeName, self.precision, self.scale)
    elseif self.precision then
        return ("%s(%d)"):format(self.typeName, self.precision)
    end
    return ("%s()"):format(self.typeName)
end

function Decimal:equals(other)
    if other == nil then
        return false
    end

    if self == other then
        return true
    end

    if getmetatable(self) == getmetatable(other) and self.precision == other.precision and self.scale == other.scale then
        return true
    end

    return false
end

return Decimal
