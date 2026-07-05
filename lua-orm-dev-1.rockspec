package = "lua-orm"
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
		["lua-orm"] = "src/orm.lua",
	}
}
