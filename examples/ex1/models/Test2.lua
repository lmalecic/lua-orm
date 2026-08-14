local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local Test2 = Model("test2", {
    { "id",             Types.Int,          Constraint.PrimaryKey, Constraint.AutoIncrement() },
	{ "char",           Types.Char(20) },
	{ "varchar",        Types.Varchar(50) },
	{ "decimal",        Types.Decimal(),    Constraint.Default(67694142) },
    { "float",   Types.Float },

    { "test", Relation.belongsTo("test", "id") }

    -- { "test", Relation.one("test", "id") }, -- automatically creates test_id FK definition
    -- { "test", Relation.one("test", "id", "customFKColumnName") }, -- automatically creates customFKColumnName FK definition
    -- { "test", Relation.one("test", "id"), Constraint.NotNull }, -- automatically creates test_id FK definition with not null
})

return Test2
