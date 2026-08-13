--- @class Query
--- @field modelClass ModelClass
--- @field context DbContext
--- @field nodes { where: table?, orderBy: table? }
local Query = {}
Query.__index = Query

--- @param modelClass ModelClass
--- @param context DbContext
function Query.new(modelClass, context)
    return setmetatable({
        modelClass = modelClass,
        context = context,
        nodes = { where = nil, orderBy = nil },
    }, Query)
end

function Query:where(expressionFunc)
    if not self.nodes.where then
        self.nodes.where = {}
    end

    table.insert(self.nodes.where, expressionFunc(self.modelClass.asProxy()))

    return self
end

function Query:orderBy(expressionFunc)
    if not self.nodes.orderBy then
        self.nodes.orderBy = {}
    end

    for _, node in ipairs({ expressionFunc(self.modelClass.asOrderProxy()) }) do
        table.insert(self.nodes.orderBy, node)
    end

    return self
end

function Query:all()
    local compiler = self.context:getCompiler()
    local sql, params = compiler:compileSelect(self)
    local result = self.context:query(sql, unpack(params))
    local entities = {}

    for _, row in ipairs(result) do
        table.insert(entities, self.context:_materialize(self.modelClass, row))
    end

    return entities
end

function Query:first()
    if not self.nodes.orderBy and self.modelClass.primaryKey then
        self:orderBy(function(entity)
            return entity[self.modelClass.primaryKey]:asc()
        end)
    elseif not self.nodes.orderBy then
        io.stderr:write("Method first() used without method orderBy() on a model dataset that doesn't have a primary key; the result will NOT be consistent\n")
    end

    local compiler = self.context:getCompiler()
    local sql, params = compiler:compileSelectFirst(self)
    local result = self.context:query(sql, unpack(params))

    if not result or not result[1] then
        return nil
    end

    return self.context:_materialize(self.modelClass, result[1])
end

return Query
