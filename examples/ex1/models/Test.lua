local Model = require("orm.model")
local Types = require("orm.model.types")
local CurrentTimestamp = require("orm.model.expressions.current-timestamp")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local Test = Model("test", {
    { "id",             Types.Int,          Constraint.PrimaryKey, Constraint.AutoIncrement() },
	{ "text",           Types.Text,         Constraint.Default("Default text"),         Constraint.NotNull },
	{ "created_at",     Types.Timestamp,    Constraint.Default(CurrentTimestamp(3)),    Constraint.NotNull },
	{ "created_at_tz",  Types.TimestampTz,  Constraint.Default(CurrentTimestamp()),     Constraint.NotNull },
	{ "char",           Types.Char(20) },
	{ "varchar",        Types.Varchar(50) },
	{ "decimal",        Types.Decimal(),    Constraint.Default(67694142) },
    { "float",         Types.Float },
    { "newColumn", Types.Int },

    -- { "test2s", Relation.hasMany("test2", "test_id") }
})

return Test
