package = "orm"
version = "dev-1"

source = {
	url = "local",
}

dependencies = {
	"lua >= 5.1",
	"pgmoon",
	"luasocket",
	"luabitop",
	"luaossl",
}

build = {
	type = "builtin",
	modules = {
		["orm"] = "src/orm/init.lua",
		["orm.field"] = "src/orm/field.lua",
		["orm.model"] = "src/orm/model.lua",
		["orm.types"] = "src/orm/types/init.lua",
		["orm.types.type"] = "src/orm/types/type.lua",
		["orm.types.int"] = "src/orm/types/int.lua",
		["orm.types.decimal"] = "src/orm/types/decimal.lua",
		["orm.types.float"] = "src/orm/types/float.lua",
		["orm.types.varchar"] = "src/orm/types/varchar.lua",
		["orm.types.char"] = "src/orm/types/char.lua",
		["orm.types.text"] = "src/orm/types/text.lua",
		["orm.types.timestamp"] = "src/orm/types/timestamp.lua",
		["orm.types.timestamptz"] = "src/orm/types/timestamptz.lua",
		["orm.current-timestamp"] = "src/orm/current-timestamp.lua",
	}
}
