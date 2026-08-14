--- @class Query
--- @field modelClass ModelClass
--- @field context DbContext
--- @field nodes { include: RelationFieldProxy[]?, where: table?, orderBy: table? }
--- @field includedRelations table<RelationFieldProxy, boolean>
local Query = {}
Query.__index = Query

--- @param modelClass ModelClass
--- @param context DbContext
function Query.new(modelClass, context)
    return setmetatable({
        modelClass = modelClass,
        context = context,
        nodes = { include = nil, where = nil, orderBy = nil },
        includedRelations = {},
    }, Query)
end

function Query:include(includeExpression)
    if not self.nodes.include then
        self.nodes.include = {}
    end

    for _, relationProxy in ipairs({ includeExpression(self.modelClass.asRelationProxy()) }) do
        if not self.includedRelations[relationProxy] then
            self.includedRelations[relationProxy] = true
            table.insert(self.nodes.include, relationProxy)
        end
    end

    return self
end

function Query:where(expression)
    if not self.nodes.where then
        self.nodes.where = {}
    end

    table.insert(self.nodes.where, expression(self.modelClass.asProxy()))
    return self
end

function Query:orderBy(expression)
    if not self.nodes.orderBy then
        self.nodes.orderBy = {}
    end

    for _, node in ipairs({ expression(self.modelClass.asOrderProxy()) }) do
        table.insert(self.nodes.orderBy, node)
    end

    return self
end

function Query:find(pkValue)
    return self:where(function(e)
        assert(self.modelClass.primaryKey, self.modelClass.tableName .. " model does not have a primary key; find() can only be called on a model with a primary key")
        local primaryKey = e[self.modelClass.primaryKey]
        return primaryKey:equals(pkValue)
    end):first()
end

--- @class QueryResultSegment
--- @field modelClass ModelClass
--- @field from integer
--- @field to integer
--- @field relation ModelRelation?

--- Builds column ranges matching PostgreSQL's SELECT * ordering: the root table
--- first, followed by each joined table in include order.
--- @param query Query
--- @return QueryResultSegment[], integer
local function buildResultSegments(query)
    local segments = {}
    local position = 1

    table.insert(segments, {
        modelClass = query.modelClass,
        from = position,
        to = position + #query.modelClass.fields - 1,
        relation = nil,
    })
    position = position + #query.modelClass.fields

    for _, relationProxy in ipairs(query.nodes.include or {}) do
        local relation = assert(query.modelClass.relations[relationProxy.relationName],
            string.format("Failed to find relation '%s.%s'",
                query.modelClass.tableName, relationProxy.relationName))
        local relationModelClass = assert(relation.referenceModel,
            string.format("Relation '%s.%s' has not been resolved by a context",
                query.modelClass.tableName, relation.name))

        table.insert(segments, {
            modelClass = relationModelClass,
            from = position,
            to = position + #relationModelClass.fields - 1,
            relation = relation,
        })
        position = position + #relationModelClass.fields
    end

    return segments, position - 1
end

--- @param query Query
--- @param result table
--- @param row table
--- @param segment QueryResultSegment
--- @return table
local function extractSegment(query, result, row, segment)
    local data = {}

    for columnIndex = segment.from, segment.to do
        local columnName = assert(result.fields[columnIndex],
            string.format("Query result is missing metadata for column %d", columnIndex))
        data[columnName] = row[columnIndex]
    end

    return query.context.connection:normalizeRow(data)
end

--- @param query Query
--- @param result table
--- @return ModelClass[]
local function materializeResult(query, result)
    assert(type(result) == "table", "Expected query_array() to return a table")
    assert(type(result.fields) == "table", "Expected query_array() result to contain a fields table")

    local segments, expectedColumnCount = buildResultSegments(query)
    assert(#result.fields == expectedColumnCount,
        string.format("Query returned %d columns, but model and include metadata expected %d",
            #result.fields, expectedColumnCount))

    local entities = {}

    for _, row in ipairs(result) do
        local rootData = extractSegment(query, result, row, segments[1])
        local rootEntity = query.context:_materialize(query.modelClass, rootData)

        for segmentIndex = 2, #segments do
            local segment = segments[segmentIndex]
            local relation = segment.relation --[[@as ModelRelation]]
            local relatedData = extractSegment(query, result, row, segment)
            local relatedEntity = nil

            -- A LEFT JOIN with no matching row yields NULL for every related
            -- column. The referenced join column is sufficient to detect it.
            if relatedData[relation.referenceColumn] ~= nil then
                relatedEntity = query.context:_materialize(segment.modelClass, relatedData)
            end

            -- _materialize() can return an identity-mapped root containing an
            -- unsaved local FK change. Do not attach stale joined data in that case.
            if rootEntity[relation.foreignKeyColumn] == rootData[relation.foreignKeyColumn] then
                query.modelClass._setLoadedRelation(rootEntity, relation.name, relatedEntity)
            end
        end

        table.insert(entities, rootEntity)
    end

    return entities
end

function Query:all()
    local compiler = self.context:getCompiler()
    local sql, params = compiler:compileSelect(self)
    local result = self.context:query_array(sql, unpack(params))

    return materializeResult(self, result)
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
    local result = self.context:query_array(sql, unpack(params))

    if not result or not result[1] then
        return nil
    end

    return materializeResult(self, result)[1]
end

return Query
