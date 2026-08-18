local Value = require("orm.change-tracking.value")

--- @class EntityEntry
--- @field entity table
--- @field modelClass ModelClass
--- @field state EntityState
--- @field originalValues table<string, any>
--- @field changedFields table<string, boolean>
local EntityEntry = {}
EntityEntry.__index = EntityEntry

--- @enum EntityState
EntityEntry.State = {
    ADDED = "ADDED",
    MODIFIED = "MODIFIED",
    DELETED = "DELETED",
    UNCHANGED = "UNCHANGED",
}

function EntityEntry.new(entity, modelClass, state)
    return setmetatable({
        entity = entity,
        modelClass = modelClass,
        state = state,
        originalValues = {},
        changedFields = {},
    }, EntityEntry)
end

function EntityEntry:recordChange(fieldName, oldValue, newValue)
    if self.state == EntityEntry.State.ADDED or self.state == EntityEntry.State.DELETED then
        return
    end

    if not self.changedFields[fieldName] then
        self.originalValues[fieldName] = Value.encode(oldValue)
    end

    local originalValue = Value.decode(self.originalValues[fieldName])
    if newValue == originalValue then
        self.changedFields[fieldName] = nil
        self.originalValues[fieldName] = nil
    else
        self.changedFields[fieldName] = true
    end

    self.state = next(self.changedFields) and EntityEntry.State.MODIFIED or EntityEntry.State.UNCHANGED
end

function EntityEntry:acceptChanges()
    self.state = EntityEntry.State.UNCHANGED
    self.originalValues = {}
    self.changedFields = {}
end

function EntityEntry:rejectChanges()
    local attributes = rawget(self.entity, "_attributes")
    for fieldName in pairs(self.changedFields) do
        attributes[fieldName] = Value.decode(self.originalValues[fieldName])
    end
    self.state = EntityEntry.State.UNCHANGED
    self.originalValues = {}
    self.changedFields = {}
end

function EntityEntry:getOriginalOrCurrentValue(fieldName)
    if self.changedFields[fieldName] then
        return Value.decode(self.originalValues[fieldName])
    end

    return self.entity[fieldName]
end

return EntityEntry
