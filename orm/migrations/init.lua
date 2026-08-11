local MigrationBuilder = require("orm.migrations.migration-builder")

--- @class Migration
--- @field up fun(migrationBuilder: MigrationBuilder)
--- @field down fun(migrationBuilder: MigrationBuilder)

local Migrations = {}

--- @param context DbContext
--- @param migration Migration
function Migrations.executeUp(context, migration)
    print("Executing migration up...")
    local builder = MigrationBuilder.new(context)
    migration.up(builder)

    local compiler = context:getCompiler()
    context:transaction(function()
        context:query(compiler:compileMigration(builder.query))
    end)
end

function Migrations.executeDown(context, migration)

end

--- @param context DbContext
--- @param schema Schema
function Migrations.generate(context, schema)
    
end

return Migrations
