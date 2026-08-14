local Connection = require("orm.connection")
local DataSet = require("orm.query.dataset")
local PgCompiler = require("orm.query.compiler.pg")
local Migrations = require("orm.migrations")
local ChangeTracker = require("orm.change-tracking.tracker")
local EntityEntry = require("orm.change-tracking.entity-entry")
local Relation = require("orm.model.relation")
local ModelRelation = require("orm.model.model-relation")

--- @alias Schema ModelClass[]

--- @class DbConfig
--- @field host string
--- @field port integer?
--- @field database string
--- @field user string?
--- @field password string?
--- @field autoMigrate boolean?
--- @field compiler any

--- @class DbContext
--- @field config DbConfig
--- @field connection Connection
--- @field _pgConnection Connection
--- @field schema Schema
--- @field modelClasses table<string, ModelClass>
--- @field data table<string, DataSet>
--- @field changeTracker ChangeTracker
local Context = {}
Context.__index = Context

function Context.new(config, schema)
    local self = setmetatable({}, Context)
    self.config = config or {}
    self.config.compiler = self.config.compiler or PgCompiler

    self.connection = Connection.new(config, self.config.compiler)
    self._pgConnection = Connection.new({
        host = config.host,
        port = config.port,
        database = self.config.compiler.MAINTENANCE_DATABASE,
        user = config.user,
        password = config.password,
    }, self.config.compiler)

    self.schema = schema

    local data = {}
    local modelClasses = {}
    local dataSets = {}

    for _, ModelClass in ipairs(schema) do
        assert(not modelClasses[ModelClass.tableName], "Model " .. ModelClass.tableName .. " already exists")
        modelClasses[ModelClass.tableName] = ModelClass
    end

    ModelRelation.setResolutionKind(Relation.Kinds.BELONGS_TO)

    local resolvedBelongsTo, resolutionError = pcall(function()
        for _, ModelClass in ipairs(schema) do
            ModelClass.resolveRelations(modelClasses)
        end
    end)

    ModelRelation.setResolutionKind(nil)

    if not resolvedBelongsTo then
        error(resolutionError, 0)
    end

    for _, ModelClass in ipairs(schema) do
        for _, relation in pairs(ModelClass.relations) do
            if relation.kind ~= Relation.Kinds.BELONGS_TO then
                relation:resolve(ModelClass, modelClasses)

                -- Relation proxies are created before owner primary-key defaults can
                -- be resolved, so publish the final generalized join metadata now.
                local proxy = ModelClass.asRelationProxy().relationFieldProxies[relation.name]
                proxy.fieldName = relation.sourceColumn
                proxy.referenceColumnName = relation.targetColumn
            end
        end
    end

    for _, ModelClass in ipairs(schema) do
        dataSets[ModelClass.tableName] = DataSet.new(ModelClass, self)
    end

    self.modelClasses = modelClasses

    self.data = setmetatable(data, {
        __index = function(_, k)
            local modelClass = assert(modelClasses[k], "Invalid index on context.data; model " .. k .. " not found")
            return dataSets[modelClass.tableName]
        end,

        __newindex = function(_, _, _)
            error("Setting values on context.data is not allowed")
        end
    })

    self.changeTracker = ChangeTracker.new(self)

    if self.config.database then
        self:ensureDatabase()
    end

    return self
end

function Context:getCompiler()
    return self.config.compiler.new(self.connection.client)
end

function Context:query(sql, ...)
    return self.connection:query(sql, ...)
end

function Context:query_array(sql, ...)
    return self.connection:query_array(sql, ...)
end

--- Runs callback atomically using this context's connection.
--- @param callback fun()
function Context:transaction(callback)
    self.connection:transaction(callback)
end

function Context:saveChanges()
    local added = self.changeTracker:entriesInState(EntityEntry.State.ADDED)
    local modified = self.changeTracker:entriesInState(EntityEntry.State.MODIFIED)
    local deleted = self.changeTracker:entriesInState(EntityEntry.State.DELETED)

    self:transaction(function()
        local compiler = self:getCompiler()

        for _, entry in ipairs(added) do
            local sql, params = compiler:compileInsert(entry)
            local result = self:query(sql, unpack(params))

            if result and result[1] then
                for fieldName, value in pairs(result[1]) do
                    rawget(entry.entity, "_attributes")[fieldName] = value
                end
            end
        end

        for _, entry in ipairs(modified) do
            local sql, params = compiler:compileUpdate(entry)
            self:query(sql, unpack(params))
        end

        for _, entry in ipairs(deleted) do
            local sql, params = compiler:compileDelete(entry)
            self:query(sql, unpack(params))
        end
    end)

    for _, entry in ipairs(added) do
        entry:acceptChanges()
    end

    for _, entry in ipairs(modified) do
        entry:acceptChanges()
    end

    for _, entry in ipairs(deleted) do
        self.changeTracker:detach(entry.entity)
    end
end

function Context:ensureDatabase()
    -- TODO: Replace with specific compiler implementation, rather than hardcoded postgres compiler
    local conn = self._pgConnection
    local result = conn:query(string.format([=[
        SELECT EXISTS (
            SELECT 1 FROM %s
            WHERE datname = $1
        );
    ]=], self.config.compiler.DATABASE_TABLE), self.config.database)

    local exists = result and result[1] and result[1].exists
    if not exists then
        conn:query(string.format("CREATE DATABASE %s", self.config.database))
    end

    conn:disconnect()
end

--- @param modelClass ModelClass
--- @param row table
function Context:_materialize(modelClass, row)
    row = self.connection:normalizeRow(row)

    local primaryKey = modelClass.primaryKey

    if primaryKey and row[primaryKey] ~= nil then
        local byModel = self.changeTracker.identityMap[modelClass]
        if byModel and byModel[row[primaryKey]] then
            return byModel[row[primaryKey]]
        end
    end

    local entity = modelClass.new(row, false)
    self.changeTracker:trackUnchanged(entity, modelClass)

    if primaryKey and row[primaryKey] ~= nil then
        local byModel = self.changeTracker.identityMap[modelClass] or {}
        byModel[row[primaryKey]] = entity
        self.changeTracker.identityMap[modelClass] = byModel
    end

    return entity
end

return Context
