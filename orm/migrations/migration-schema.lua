local MigrationSchema = {}
MigrationSchema.__index = MigrationSchema

function MigrationSchema.new(connection)
    local self = setmetatable({}, MigrationSchema)
    self.connection = connection
    return self
end

function MigrationSchema:createTable(name, fields)
    local definitions = {}

    for _, field in ipairs(fields) do
        table.insert(definitions, field:toSql())
    end
end

return MigrationSchema
