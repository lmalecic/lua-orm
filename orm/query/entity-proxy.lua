--- @class EntityProxy
--- @field modelClass ModelClass
--- @field proxies table
local EntityProxy = {}
EntityProxy.__index = EntityProxy

function EntityProxy.new(modelClass, proxies)
    local self = {}
    self.modelClass = modelClass
    self.proxies = proxies
    return setmetatable(self, EntityProxy)
end

function EntityProxy:__index(key)
    assert(self.proxies[key] ~= nil, "Field '" .. key .. "' does not exist on EntityProxy")
    return self.proxies[key]
end

function EntityProxy:__newindex(key, value)
    error("Cannot create new field '" .. key .. "' on EntityProxy")
end

return EntityProxy
