local Orm = require("orm")

local config = {
	host = os.getenv("PGHOST") or "127.0.0.1",
	port = tonumber(os.getenv("PGPORT")) or 5432,
	database = os.getenv("PGDATABASE") or "medix",
	user = os.getenv("PGUSER") or "medix",
	password = os.getenv("PGPASSWORD") or "medix",
}

local schema = require("schema")

for _, v in ipairs(schema) do
	print(v.table)
	for _, col in ipairs(v.fields) do
        print(col:toSql())
	end
	print("\n")
end

local db = Orm.new(config, schema)
