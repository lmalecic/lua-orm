--- @class RelationFieldProxy
--- @field tableName string
--- @field relationName string
--- @field fieldName string
--- @field referenceTableName string
--- @field referenceColumnName string
--- @field required boolean
local RelationFieldProxy = {}
RelationFieldProxy.__index = RelationFieldProxy

--- @param tableName string
--- @param relationName string
--- @param fieldName string
--- @param referenceTableName string
--- @param referenceColumnName string
--- @param required boolean
function RelationFieldProxy.new(tableName, relationName, fieldName, referenceTableName, referenceColumnName, required)
    return setmetatable({
        tableName = tableName,
        relationName = relationName,
        fieldName = fieldName,
        referenceTableName = referenceTableName,
        referenceColumnName = referenceColumnName,
        required = required,
    }, RelationFieldProxy)
end

function RelationFieldProxy:__newindex(key, value)
    error(string.format("Failed to set %s to %s; RelationFieldProxy is read-only", key, value))
end

return RelationFieldProxy
