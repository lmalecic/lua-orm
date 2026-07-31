local SchemaSync = {}

local function quoteIdentifier(name)
    return '"' .. tostring(name):gsub('"', '""') .. '"'
end

local function createTableStatement(model)
    assert(type(model.name) == "string" and model.name ~= "", "Model name must be a non-empty string")
    assert(type(model.fields) == "table" and #model.fields > 0, "Model " .. model.name .. " must have at least one field")

    local columns = {}
    for _, field in ipairs(model.fields) do
        table.insert(columns, field:toSql())
    end

    return string.format("CREATE TABLE IF NOT EXISTS %s (%s);", quoteIdentifier(model.name), table.concat(columns, ", "))
end

--- @param connection Connection
--- @param schema Schema
--- @param opts { execute: boolean? }?
--- @return string[]
function SchemaSync.apply(connection, schema, opts)
    assert(type(schema) == "table", "Schema must be a table of models")
    opts = opts or {}

    local statements = {}
    for _, model in ipairs(schema) do
        table.insert(statements, createTableStatement(model))
    end

    if opts.execute then
        for _, statement in ipairs(statements) do
            connection:query(statement)
        end
    end

    return statements
end

return SchemaSync
