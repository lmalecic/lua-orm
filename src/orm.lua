local pgmoon = require("pgmoon")

local Orm = {}
Orm.__index = Orm

function Orm.new(config, schema)
	local self = setmetatable({}, Orm)
	self.client = pgmoon.new(config)
	self.schema = schema
	return self
end

return Orm
