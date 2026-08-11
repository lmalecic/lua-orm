local Field = require("orm.model.field")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Alter = require("orm.migrations.alter")

local Migration = {}
Migration.version = "0-initial-migration"

--- @param migrationBuilder MigrationBuilder
function Migration.up(migrationBuilder)
    migrationBuilder:createTable("foreign_table", {
        { "id", Types.Int, Constraint.PrimaryKey },
    })

    migrationBuilder:createTable("users", {
        { "id", Types.Int, Constraint.PrimaryKey },
        { "unique_column", Types.Text, Constraint.Unique },
        { "foreign_key_column", Types.Int, Constraint.ForeignKey("foreign_table", "id") }
    })
end

--- @param migrationBuilder MigrationBuilder
function Migration.down(migrationBuilder)

end

return Migration
