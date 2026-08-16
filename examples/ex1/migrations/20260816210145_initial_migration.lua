local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Alter = require("orm.migrations.alter")
local CurrentTimestamp = require("orm.model.expressions.current-timestamp")

local Migration = {}
Migration.version = "20260816210145_initial_migration"

--- @param migrationBuilder MigrationBuilder
function Migration.up(migrationBuilder)
    migrationBuilder:createTable("test", { { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS), Constraint.NotNull },
		{ "text", Types.Text, Constraint.NotNull, Constraint.Default("Default text") },
		{ "created_at", Types.Timestamp, Constraint.NotNull, Constraint.Default(CurrentTimestamp(3)) },
		{ "created_at_tz", Types.TimestampTz, Constraint.NotNull, Constraint.Default(CurrentTimestamp()) },
		{ "char", Types.Char(20) },
		{ "varchar", Types.Varchar(50) },
		{ "decimal", Types.Decimal(), Constraint.Default(67694142) },
		{ "float", Types.Float } })
    migrationBuilder:createTable("test2", { { "id", Types.Int, Constraint.PrimaryKey, Constraint.AutoIncrement(Constraint.IdentityMode.ALWAYS), Constraint.NotNull },
		{ "char", Types.Char(20) },
		{ "varchar", Types.Varchar(50) },
		{ "decimal", Types.Decimal(), Constraint.Default(67694142) },
		{ "float", Types.Float },
		{ "test_id", Types.Int, Constraint.ForeignKey("test", "id") } })
end

--- @param migrationBuilder MigrationBuilder
function Migration.down(migrationBuilder)
    migrationBuilder:dropTable("test2")
    migrationBuilder:dropTable("test")
end

return Migration
