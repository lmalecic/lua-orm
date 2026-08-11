local Field = require("orm.model.field")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Alter = require("orm.migrations.alter")

local Migration = {}
Migration.version = "2-migration"

--- @param migrationBuilder MigrationBuilder
function Migration.up(migrationBuilder)
    migrationBuilder:alterTable("users", {
        Alter.addForeignKeyConstraint("users_foreign_key_column_fkey", "foreign_key_column", "foreign_table", "id")
    })
end

--- @param migrationBuilder MigrationBuilder
function Migration.down(migrationBuilder)

end

return Migration
