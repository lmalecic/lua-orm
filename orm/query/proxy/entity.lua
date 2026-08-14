--- @class EntityProxy
--- @field modelClass ModelClass
--- @field proxies table
local EntityProxy = {}
EntityProxy.__index = EntityProxy

function EntityProxy.new(modelClass, proxies)
    return setmetatable({
        modelClass = modelClass,
        proxies = proxies,
    }, EntityProxy)
end

function EntityProxy:__index(key)
    assert(self.proxies[key] ~= nil, "Field '" .. key .. "' does not exist on EntityProxy")
    return self.proxies[key]
end

function EntityProxy:__newindex(key, value)
    error("Cannot create new field '" .. key .. "' on EntityProxy")
end

return EntityProxy
