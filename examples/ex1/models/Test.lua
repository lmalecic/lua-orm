local Model = require("orm.model")
local Field = require("orm.model.field")
local Types = require("orm.model.types")
local CurrentTimestamp = require("orm.model.current-timestamp")

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
Test.__index = Test

return Test
