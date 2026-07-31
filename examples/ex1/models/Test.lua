local Model = require("orm.metadata.model")
local Field = require("orm.metadata.field")
local Types = require("orm.metadata.types")
local CurrentTimestamp = require("orm.metadata.current-timestamp")

local Test = Model("test", {
	Field("id", Types.Int):primaryKey(),
	Field("text", Types.Text)
		:default("Default text")
		:notNull(),
	Field("created_at", Types.Timestamp)
		:default(CurrentTimestamp(3))
		:notNull(),
	Field("created_at_tz", Types.TimestampTz)
		:default(CurrentTimestamp())
		:notNull(),
	Field("char", Types.Char(20)),
	Field("varchar", Types.Varchar(50)),
	Field("decimal", Types.Decimal())
		:default(67694142),
	Field("float", Types.Float),
})

function Test.new()
    local self = setmetatable({}, Test)
	return self
end

return Test
