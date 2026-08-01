--- @class Model
--- @field name string
--- @field fields { [number]: Field }
local Model = setmetatable({}, {
	--- @param name string
	--- @param fields { [number]: Field }
	__call = function(self, name, fields)
		return self.new(name, fields)
	end,
})
Model.__index = Model

--- @param name string
--- @param fields { [number]: Field }
function Model.new(name, fields)
    local self = setmetatable({}, Model)
    self.name = name
    self.fields = fields
    return self
end

return Model
