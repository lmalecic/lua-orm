local Connection = require("orm.core.connection")

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
	return self
end

return Context
