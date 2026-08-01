--- @class DataSet
--- @field model Model
local DataSet = {}
DataSet.__index = DataSet

--- @param model Model
function DataSet.new(model)
    local self = setmetatable({}, DataSet)
    self.model = model
    return self
end

function DataSet:add(entity)

end

function DataSet:remove(entity)

end

function DataSet:all()

end

function DataSet:find(id)

end

function DataSet:where(expressionFunc)

end

function DataSet:orderBy(selector, direction)

end

return DataSet
