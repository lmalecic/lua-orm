--- @class DataSet
--- @field modelClass ModelClass
--- @field context DbContext
local DataSet = {}
DataSet.__index = DataSet

--- @param modelClass ModelClass
function DataSet.new(modelClass, context)
    local self = setmetatable({}, DataSet)
    self.modelClass = modelClass
    self.context = context
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
    local expression = expressionFunc(self.modelClass.asProxy())
    local compiler = self.context:getCompiler()
    local compiled, params = compiler:compile(expression)

    print("Compiled expression:", compiled, table.concat(params, ", "))
end

function DataSet:orderBy(selector, direction)

end

return DataSet
