local Connection = require("orm.core.connection")
local DataSet = require("orm.runtime.dataset")

--- @class Schema: { [number]: Field } }

--- @class DbContext
--- @field config ConnectionConfig
--- @field connection Connection
--- @field schema Schema
--- @field data table<string, DataSet>
local Context = {}
Context.__index = Context

function Context.new(config, schema)
    local self = setmetatable({}, Context)
    self.config = config or {}
    self.connection = Connection.new(config)
    self.schema = schema
    self.data = {}

    for _, model in ipairs(schema) do
        assert(not self.data[model.name], "Table " .. model.name .. " already exists!")
        self.data[model.name] = DataSet.new(model)
    end

    return self
end

function Context:saveChanges()

end

return Context
