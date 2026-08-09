local Connection = require("orm.connection")
local DataSet = require("orm.query.dataset")
local PgCompiler = require("orm.query.compiler.pg")

--- @class Schema: { [number]: Field } }

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
--- @field data table<string, DataSet>
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

    for _, model in ipairs(schema) do
        assert(not data[model.tableName], "Model " .. model.tableName .. " already exists")
        modelClasses[model.tableName] = model
        print(self:getCompiler():compileCreateTable(model))
    end

    self.data = setmetatable(data, {
        __index = function(_, k)
            local modelClass = modelClasses[k]
            assert(modelClass, "Invalid index on context.data; model " .. k .. " not found")
            return DataSet.new(modelClass, self)
        end,

        __newindex = function(_, _, _)
            error("Setting values on context.data is not allowed")
        end
    })

    self:ensureDatabase()

    return self
end

function Context:getCompiler()
    return self.config.compiler.new(self.connection.client)
end

function Context:query(sql, ...)
    return self.connection:query(sql, ...)
end

--- Runs callback atomically using this context's connection.
--- @param callback fun()
function Context:transaction(callback)
    self.connection:transaction(callback)
end

function Context:saveChanges()

end

function Context:ensureDatabase()
    -- TODO: Replace with specific compiler implementation, rather than hardcoded postgres compiler
    local conn = self._pgConnection
    local result = conn:query(string.format([=[
        SELECT EXISTS (
            SELECT 1 FROM %s
            WHERE datname = $1
        )
    ]=], self.config.compiler.DATABASE_TABLE), self.config.database)

    local exists = result and result[1] and result[1].exists
    if not exists then
        conn:query(string.format("CREATE DATABASE %s", self.config.database))
    end

    conn:disconnect()
end

return Context
