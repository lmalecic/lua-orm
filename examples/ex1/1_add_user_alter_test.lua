local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Alter = require("orm.migrations.alter")
local CurrentTimestamp = require("orm.model.expressions.current-timestamp")

local Migration = {}
Migration.version = "1_add_user_alter_test"

--- @param migrationBuilder MigrationBuilder
function Migration.up(migrationBuilder)
    migrationBuilder:createTable("user", {
        { "id",             Types.Int,          Constraint.PrimaryKey,  Constraint.AutoIncrement() },
    	{ "username",       Types.Text,         Constraint.NotNull },
    })

    migrationBuilder:alterTable("test", {
        Alter.addColumn({ "user_id", Types.Int, Constraint.ForeignKey("user", "id") })
    })
end

--- @param migrationBuilder MigrationBuilder
function Migration.down(migrationBuilder)
    migrationBuilder:alterTable("test", {
        Alter.dropColumn("user_id")
    })
    migrationBuilder:dropTable("user")
end

return Migration
