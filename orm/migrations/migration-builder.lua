local Field = require("orm.model.field")

--- @class MigrationBuilder
--- @field context DbContext
--- @field query string[]
local MigrationBuilder = {}
MigrationBuilder.__index = MigrationBuilder

--- @param context DbContext
--- @return MigrationBuilder
function MigrationBuilder.new(context)
    local self = setmetatable({}, MigrationBuilder)
    self.context = context
    self.query = {}
    return self
end

function MigrationBuilder:createTable(name, fieldDefinitions)
    local fields = {}

    if #fieldDefinitions > 0 then
        for _, definition in ipairs(fieldDefinitions) do
            table.insert(fields, Field.new(definition))
        end
    end

    table.insert(self.query, self.context:getCompiler():compileCreateTable(name, fields))
end

function MigrationBuilder:dropTable(name)
    table.insert(self.query, self.context:getCompiler():compileDropTable(name))
end

function MigrationBuilder:alterTable(name, alterations)
    table.insert(self.query, self.context:getCompiler():compileAlterTable(name, alterations))
end

return MigrationBuilder
