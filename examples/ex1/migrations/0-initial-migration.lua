local Field = require("orm.model.field")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Alter = require("orm.migrations.alter")

local Migration = {}
Migration.version = "0-initial-migration"

--- @param migrationBuilder MigrationBuilder
function Migration.up(migrationBuilder)
    migrationBuilder:createTable("users", {
        { "id", Types.Int, Constraint.PrimaryKey },
        { "unique_column", Types.Text, Constraint.Unique }
    })
end

--- @param migrationBuilder MigrationBuilder
function Migration.down(migrationBuilder)

end

return Migration
