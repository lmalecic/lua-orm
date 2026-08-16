local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Alter = require("orm.migrations.alter")
local CurrentTimestamp = require("orm.model.expressions.current-timestamp")

local Migration = {}
Migration.version = "0_initial_migration"

--- @param migrationBuilder MigrationBuilder
function Migration.up(migrationBuilder)
    migrationBuilder:createTable("test", {
        { "id",             Types.Int,          Constraint.PrimaryKey,                      Constraint.AutoIncrement() },
    	{ "text",           Types.Text,         Constraint.Default("Default text"),         Constraint.NotNull },
    	{ "created_at",     Types.Timestamp,    Constraint.Default(CurrentTimestamp(3)),    Constraint.NotNull },
    	{ "created_at_tz",  Types.TimestampTz,  Constraint.Default(CurrentTimestamp()),     Constraint.NotNull },
    	{ "char",           Types.Char(20) },
    	{ "varchar",        Types.Varchar(50) },
    	{ "decimal",        Types.Decimal(),    Constraint.Default(67694142) },
    	{ "float",          Types.Float },
    })

    migrationBuilder:createTable("test2", {
        { "id",         Types.Int,          Constraint.PrimaryKey, Constraint.AutoIncrement() },
    	{ "char",       Types.Char(20) },
    	{ "varchar",    Types.Varchar(50) },
    	{ "decimal",    Types.Decimal(),    Constraint.Default(67694142) },
        { "float",      Types.Float },
    	{ "test_id",    Types.Int,          Constraint.ForeignKey("test", "id") }
    })
end

--- @param migrationBuilder MigrationBuilder
function Migration.down(migrationBuilder)
    migrationBuilder:dropTable("test2")
    migrationBuilder:dropTable("test")
end

return Migration
