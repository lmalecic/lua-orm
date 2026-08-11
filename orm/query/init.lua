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
    -- compile
    local compiler = self.context:getCompiler()
    local sql, params = compiler:compileSelect(self)
    print(sql, params)
    -- execute on connection
    local result = self.context:query(sql, unpack(params))
    local entities = {}

    for _, row in ipairs(result) do
        table.insert(entities, self.modelClass.new(row))
    end

    return entities
end

function Query:first()
    -- compile
end

return Query
