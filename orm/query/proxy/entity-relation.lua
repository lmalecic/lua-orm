--- @class EntityRelationProxy
--- @field modelClass ModelClass
--- @field relationFieldProxies table<string, RelationFieldProxy>
local EntityRelationProxy = {}
EntityRelationProxy.__index = EntityRelationProxy

function EntityRelationProxy.new(modelClass, relationFieldProxies)
    return setmetatable({
        modelClass = modelClass,
        relationFieldProxies = relationFieldProxies,
    }, EntityRelationProxy)
end

function EntityRelationProxy:__index(key)
    local relationFieldProxy = rawget(self, "relationFieldProxies")[key]
    if relationFieldProxy then
        return relationFieldProxy
    end
    error(string.format("Failed to index %s; no such relation field in table %s", key, rawget(self, "modelClass").tableName))
end

function EntityRelationProxy:__newindex(key, value)
    error(string.format("Failed to set %s to %s; EntityRelationProxy is read-only", key, value))
end

return EntityRelationProxy
