local Field = require("orm.model.field")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Alter = require("orm.migrations.alter")

local Migration = {}
Migration.version = "1-migration"

--- @param migrationBuilder MigrationBuilder
function Migration.up(migrationBuilder)
    migrationBuilder:alterTable("users", {
        Alter.dropConstraint("users_foreign_key_column_fkey")
    })
end

--- @param migrationBuilder MigrationBuilder
function Migration.down(migrationBuilder)

end

return Migration
