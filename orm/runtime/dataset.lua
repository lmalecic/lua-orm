local EntityState = require("orm.runtime.entity_state")

--- @class DataSet
--- @field model Model
--- @field _entities table
--- @field _states table
--- @field _pkField Field?
local DataSet = {}
DataSet.__index = DataSet

--- @param model Model
function DataSet.new(model)
    local self = setmetatable({}, DataSet)
    self.model = model
    self._entities = {}
    self._states = setmetatable({}, { __mode = "k" })
    self._pkField = DataSet._findPrimaryKey(model)
    return self
end

function DataSet:add(entity)
    assert(type(entity) == "table", "Entity must be a table")
    local id = self:_entityId(entity)
    if id ~= nil and self:find(id) ~= nil then
        error("Entity with key " .. tostring(id) .. " already exists in dataset")
    end
    table.insert(self._entities, entity)
    self._states[entity] = EntityState.ADDED
    return entity
end

function DataSet:remove(entity)
    local index = self:_indexOf(entity)
    if not index then
        error("Entity is not tracked by this dataset")
    end
    self._states[entity] = EntityState.DELETED
    table.remove(self._entities, index)
    return entity
end

function DataSet:find(id)
    if self._pkField == nil then
        error("Cannot use find(id) without a primary key field")
    end
    for _, entity in ipairs(self._entities) do
        if entity[self._pkField.name] == id then
            return entity
        end
    end
    return nil
end

function DataSet:all()
    return self:_cloneEntities()
end

function DataSet:where(predicate)
    if type(predicate) ~= "function" then
        error("DataSet:where currently supports function predicates only")
    end
    local out = {}
    for _, entity in ipairs(self._entities) do
        if predicate(entity) then
            table.insert(out, entity)
        end
    end
    return out
end

function DataSet:orderBy(selector, direction)
    direction = direction or "asc"
    local descending = direction == "desc"
    if not (direction == "asc" or direction == "desc") then
        error("direction must be 'asc' or 'desc'")
    end

    local keySelector
    if type(selector) == "string" then
        keySelector = function(entity)
            return entity[selector]
        end
    elseif type(selector) == "function" then
        keySelector = selector
    else
        error("selector must be a field name or function")
    end

    local sorted = self:_cloneEntities()
    table.sort(sorted, function(a, b)
        local av = keySelector(a)
        local bv = keySelector(b)
        if descending then
            return av > bv
        end
        return av < bv
    end)
    return sorted
end

function DataSet:stateOf(entity)
    return self._states[entity] or EntityState.UNCHANGED
end

function DataSet:markModified(entity)
    if self:_indexOf(entity) == nil then
        error("Entity is not tracked by this dataset")
    end
    if self:stateOf(entity) ~= EntityState.ADDED then
        self._states[entity] = EntityState.MODIFIED
    end
end

function DataSet:_entityId(entity)
    if self._pkField == nil then
        return nil
    end
    return entity[self._pkField.name]
end

function DataSet:_indexOf(entity)
    for index, candidate in ipairs(self._entities) do
        if candidate == entity then
            return index
        end
    end
    return nil
end

function DataSet:_cloneEntities()
    local copy = {}
    for _, entity in ipairs(self._entities) do
        table.insert(copy, entity)
    end
    return copy
end

--- @param model Model
--- @return Field?
function DataSet._findPrimaryKey(model)
    if model == nil or type(model.fields) ~= "table" then
        return nil
    end
    for _, field in ipairs(model.fields) do
        if field.isPrimaryKey then
            return field
        end
    end
    return nil
end

return DataSet
