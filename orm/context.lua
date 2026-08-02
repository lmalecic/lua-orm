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
    self.data = {}

    for _, model in ipairs(schema) do
        assert(not self.data[model.tableName], "Table " .. model.tableName .. " already exists!")
        self.data[model.tableName] = DataSet.new(model, self)
    end

    return self
end

function Context:getCompiler()
	return self.config.compilerClass.new()
end

function Context:saveChanges()

end

return Context
