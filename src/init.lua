local pgmoon = require("pgmoon")
local pg = pgmoon.new({
	host = os.getenv("PGHOST"),
	port = tonumber(os.getenv("PGPORT")),
	database = os.getenv("PGDATABASE"),
	user = os.getenv("PGUSER"),
	password = os.getenv("PGPASSWORD"),
})

assert(pg:connect())

local Orm = {}



return Orm
