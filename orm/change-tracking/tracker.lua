local EntityEntry = require("orm.change-tracking.entity-entry")

--- @class ChangeTracker
--- @field context DbContext
--- @field entries table<table, EntityEntry>
--- @field identityMap table<table, table>
local ChangeTracker = {}
ChangeTracker.__index = ChangeTracker

--- @param context DbContext
function ChangeTracker.new(context)
    return setmetatable({
        context = context,
        entries = setmetatable({}, { __mode = "k" }),
        identityMap = {},
    }, ChangeTracker)
end

--- @param entity any
--- @return EntityEntry?
function ChangeTracker:getEntry(entity)
    return self.entries[entity]
end

--- @param entity any
--- @param modelClass ModelClass
--- @param state EntityState
--- @return EntityEntry
function ChangeTracker:_track(entity, modelClass, state)
    local existing = self.entries[entity]
    if existing then
        assert(existing.modelClass == modelClass, "Entity belongs to another model")
        return existing
    end

    local entry = EntityEntry.new(entity, modelClass, state)
    self.entries[entity] = entry
    rawset(entity, "_entry", entry)
    -- entity._entry = entry

    return entry
end

--- @param entity any
--- @param modelClass ModelClass
--- @return EntityEntry
function ChangeTracker:trackUnchanged(entity, modelClass)
    return self:_track(entity, modelClass, EntityEntry.State.UNCHANGED)
end

--- @param entity any
--- @param modelClass ModelClass
--- @return EntityEntry
function ChangeTracker:trackAdded(entity, modelClass)
    local entry = self:_track(entity, modelClass, EntityEntry.State.ADDED)
    entry.state = EntityEntry.State.ADDED
    return entry
end

--- @param entity any
--- @param modelClass ModelClass
--- @return EntityEntry?
function ChangeTracker:markDeleted(entity, modelClass)
    local entry = self:_track(entity, modelClass, EntityEntry.State.UNCHANGED)

    if entry.state == EntityEntry.State.ADDED then
        self:detach(entity)
        return nil
    end

    entry.state = EntityEntry.State.DELETED
    return entry
end

function ChangeTracker:detach(entity)
    rawset(entity, "_entry", nil)
    -- entity._entry = nil
    self.entries[entity] = nil
    self.identityMap[entity] = nil
end

--- @param state EntityState
--- @return EntityEntry[]
function ChangeTracker:entriesInState(state)
    local result = {}

    for _, entry in pairs(self.entries) do
        if entry.state == state then
            table.insert(result, entry)
        end
    end

    return result
end

return ChangeTracker
