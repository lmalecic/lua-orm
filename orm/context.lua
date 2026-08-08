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
--- @field compilerClass any

--- @class DbContext
--- @field config DbConfig
--- @field connection Connection
--- @field schema Schema
--- @field data table<string, DataSet>
local Context = {}
Context.__index = Context

function Context.new(config, schema)
    local self = setmetatable({}, Context)
    self.config = config or {}
    self.config.compilerClass = self.config.compilerClass or PgCompiler

    self.connection = Connection.new(config)
    self.schema = schema

    local data = {}
    local modelClasses = {}

    for _, model in ipairs(schema) do
        assert(not data[model.tableName], "Model " .. model.tableName .. " already exists")
        modelClasses[model.tableName] = model
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

    return self
end

function Context:getCompiler()
	return self.config.compilerClass.new(self.connection.client)
end

function Context:saveChanges()

end

return Context
