--- @class CurrentTimestamp : GeneratorReferenceable
--- @field precision integer?
local CurrentTimestamp = setmetatable({}, {
    --- @param precision integer?
	--- @return CurrentTimestamp
	__call = function(self, precision)
    	return self.new(precision)
    end
})
CurrentTimestamp.__index = CurrentTimestamp
CurrentTimestamp.class = CurrentTimestamp

--- @param precision integer?
--- @return CurrentTimestamp
function CurrentTimestamp.new(precision)
    local self = setmetatable({}, CurrentTimestamp)
    self.precision = precision
    return self
end

function CurrentTimestamp:format()
    if self.precision then
        return string.format("CURRENT_TIMESTAMP(%d)", self.precision)
    end

    return "CURRENT_TIMESTAMP"
end

function CurrentTimestamp:toGeneratorReferenceString()
    if self.precision then
        return ("CurrentTimestamp(%s)"):format(string.format("%d", self.precision))
    end
    return "CurrentTimestamp()"
end

function CurrentTimestamp:equals(other)
    if other == nil then
        return false
    end

    if self == other then
        return true
    end

    local otherMt = getmetatable(other)
    if type(other) == "table" and otherMt == CurrentTimestamp then
        return self.precision == other.precision
    end

    return false
end

return CurrentTimestamp
