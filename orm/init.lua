local pgmoon = require("pgmoon")

--- @class Orm
--- @field client any
--- @field schema Schema
--- @field data any
local Orm = {}
Orm.__index = Orm

--- @class DbConfig
--- @field host string
--- @field port integer
--- @field database string
--- @field user string
--- @field password string

--- @param config DbConfig
--- @param schema Schema
--- @return Orm
function Orm.new(config, schema)
	local self = setmetatable({}, Orm)
	self.client = pgmoon.new(config)
	self.schema = schema
	self.data = {}

	self:_initData()

	return self
end

function Orm:_initData()
    for _, table in pairs(self.schema) do

    end
end

function Orm:saveChanges()

end

return Orm
