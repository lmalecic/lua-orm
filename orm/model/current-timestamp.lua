--- @class CurrentTimestamp
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

function CurrentTimestamp:__tostring()
    if self.precision then
    	return string.format("CURRENT_TIMESTAMP(%d)", self.precision)
    end

	return "CURRENT_TIMESTAMP"
end

return CurrentTimestamp
