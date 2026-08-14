local Query = require("orm.query")

--- @class DataSet
--- @field modelClass ModelClass
--- @field context DbContext
--- @field nodes { where: { }, orderBy: { } }
local DataSet = {}
DataSet.__index = DataSet

--- @param modelClass ModelClass
function DataSet.new(modelClass, context)
    local self = setmetatable({}, DataSet)
    self.modelClass = modelClass
    self.context = context
    return self
end

function DataSet:include(includeExpression)
    return Query.new(self.modelClass, self.context):include(includeExpression)
end

function DataSet:add(entity)
    assert(type(entity) == "table", "DataSet:add() expects an entity")
    assert(getmetatable(entity) == self.modelClass, "Cannot add entity to a DataSet for a different model")
    self.context.changeTracker:trackAdded(entity, self.modelClass)
    return entity
end

function DataSet:remove(entity)
    assert(type(entity) == "table", "DataSet:remove() expects an entity")
    assert(getmetatable(entity) == self.modelClass, "Cannot remove entity from a DataSet for a different model")
    self.context.changeTracker:markDeleted(entity, self.modelClass)
    return entity
end

function DataSet:all()
    return Query.new(self.modelClass, self.context):all()
end

function DataSet:first()
    return Query.new(self.modelClass, self.context):first()
end

function DataSet:find(pkValue)
    return Query.new(self.modelClass, self.context):where(function(e)
        assert(self.modelClass.primaryKey, self.modelClass.tableName .. " model does not have a primary key; find() can only be called on a model with a primary key")
        local primaryKey = e[self.modelClass.primaryKey]
        return primaryKey:equals(pkValue)
    end):first()
end

function DataSet:where(expressionFunc)
    return Query.new(self.modelClass, self.context):where(expressionFunc)
end

function DataSet:orderBy(selectorExpressionFunc)
    return Query.new(self.modelClass, self.context):orderBy(selectorExpressionFunc)
end

return DataSet
