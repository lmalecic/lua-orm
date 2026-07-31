package = "orm"
version = "dev-1"

source = {
	url = "local",
}

dependencies = {
	"lua >= 5.1",
	"pgmoon 1.17.0-1",
	"luasocket 3.1.0-1",
	"luabitop 1.0.3-1",
	"luaossl 20250929-0",
}

build = {
	type = "builtin",
}
