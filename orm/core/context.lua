local Connection = require("orm.core.connection")
local DataSet = require("orm.runtime.dataset")
local SchemaSync = require("orm.migrations.schema_sync")

--- @class Schema: { [number]: Model } }

--- @class DbContext
--- @field config DbConfig
--- @field connection Connection
--- @field schema Schema
--- @field data table<string, DataSet>
local DbContext = {}
DbContext.__index = DbContext

--- @class DbConfig
--- @field host string
--- @field port integer
--- @field database string
--- @field user string
--- @field password string

--- @param config DbConfig
--- @param schema Schema | fun(): Schema
--- @return DbContext
function DbContext.new(config, schema)
    local self = setmetatable({}, DbContext)
    self.config = config or {}
    self.connection = Connection.new(config)
    self.schema = DbContext._resolveSchema(schema)
    self.data = {}

    self:_updateSchema()
    self:_initData()

    return self
end

--- @param schema Schema|fun(): Schema
--- @return Schema
function DbContext._resolveSchema(schema)
    if schema == nil then
        return {}
    end

    if type(schema) == "function" then
        local resolved = schema()
        assert(type(resolved) == "table", "Schema provider must return a model table")
        return resolved
    end

    assert(type(schema) == "table", "Schema must be a model table or schema provider function")
    return schema
end

function DbContext:_updateSchema()
    SchemaSync.apply(self.connection, self.schema, {
        execute = self.config.autoMigrate == true,
    })
end

function DbContext:_initData()
    for _, model in ipairs(self.schema) do
        assert(not self.data[model.name], "Table " .. model.name .. " already exists")
        local set = DataSet.new(model)
        self.data[model.name] = set
        self[model.name] = set
    end
end

function DbContext:saveChanges()
    -- Stub for future UnitOfWork integration.
end

return DbContext
