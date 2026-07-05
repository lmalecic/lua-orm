local Orm = require("src.orm")
local Model = require("src.model")
local Column = require("src.column")
local Types = require("src.types.init")

local schema = {
	Model.new("test", {
		Column("id", Types.Int):primaryKey(),
		Column("text", Types.Text)
			:default("Default text")
			:notNull(),
		Column("created_at", Types.Timestamp)
			:default("CURRENT_TIMESTAMP")
			:notNull(),
		Column("created_at_tz", Types.TimestampTz)
			:default("CURRENT_TIMESTAMP")
			:notNull(),
		Column("char", Types.Char(20)),
		Column("varchar", Types.Varchar(50)),
		Column("decimal", Types.Decimal()):default(67694142),
		Column("float", Types.Float),
	})
}

for _, v in ipairs(schema) do
	print(v.tableName)
	for _, col in ipairs(v.columns) do
		print(col:toSql())
	end
	print("\n")
end

local db = Orm.new({
	host = os.getenv("PGHOST") or "127.0.0.1",
	port = tonumber(os.getenv("PGPORT")) or 5432,
	database = os.getenv("PGDATABASE") or "medix",
	user = os.getenv("PGUSER") or "medix",
	password = os.getenv("PGPASSWORD") or "medix",
}, schema)
