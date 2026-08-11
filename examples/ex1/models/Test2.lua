local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")

local Test2 = Model("test2", {
    { "id",             Types.Int,          Constraint.PrimaryKey },
	{ "char",           Types.Char(20) },
	{ "varchar",        Types.Varchar(50) },
	{ "decimal",        Types.Decimal(),    Constraint.Default(67694142) },
	{ "float",          Types.Float },
})

return Test2
