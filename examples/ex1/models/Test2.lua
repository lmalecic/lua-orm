local Model = require("orm.metadata.model")
local Field = require("orm.metadata.field")
local Types = require("orm.metadata.types")
local CurrentTimestamp = require("orm.current-timestamp")

local Test2 = Model("test2", {
	Field("id", Types.Int):primaryKey(),
	Field("char", Types.Char(20)),
	Field("varchar", Types.Varchar(50)),
	Field("decimal", Types.Decimal())
		:default(67694142),
	Field("float", Types.Float),
})

function Test2.new()
    local self = setmetatable({}, Test2)
	return self
end

return Test2
