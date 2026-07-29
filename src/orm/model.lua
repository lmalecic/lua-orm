--- @class Model
--- @field table string
--- @field fields { [number]: Field }
local Model = setmetatable({}, {
	--- @param tableName string
	--- @param fields { [number]: Field }
	__call = function(self, tableName, fields)
		return self.new(tableName, fields)
	end,
})
Model.__index = Model

--- @param tableName string
--- @param fields { [number]: Field }
function Model.new(tableName, fields)
    local self = setmetatable({}, Model)
    self.table = tableName
    self.fields = fields
    return self
end

return Model
