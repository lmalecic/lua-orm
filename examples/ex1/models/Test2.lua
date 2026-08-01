local Model = require("orm.model")
local Field = require("orm.model.field")
local Types = require("orm.model.types")

local Test2 = Model("test2", {
	Field("id", Types.Int):primaryKey(),
	Field("char", Types.Char(20)),
	Field("varchar", Types.Varchar(50)),
	Field("decimal", Types.Decimal())
		:default(67694142),
	Field("float", Types.Float),
})
Test2.__index = Test2

function Test2.new()
    local self = setmetatable({}, Test2)
	return self
end

return Test2
