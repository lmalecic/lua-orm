--- @class Model
--- @field name string
--- @field fields { [number]: Field }
local Model = setmetatable({}, {
    --- @param tableName string
    --- @param fields { [number]: Field }
    __call = function(self, tableName, fields)
        return self.new(tableName, fields)
    end,
})
Model.__index = Model

--- @param name string
--- @param fields { [number]: Field }
function Model.new(name, fields)
    local self = setmetatable({}, Model)
    self.__index = self
    self.name = name
    self.fields = fields
    return self
end

return Model
