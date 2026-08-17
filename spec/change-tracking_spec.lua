---@diagnostic disable: undefined-global, undefined-field

local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Context = require("orm.context")

local EntityEntry = require("orm.change-tracking.entity-entry")
local State = EntityEntry.State

describe("change tracking", function()
    --- @type ModelClass
    local test
    --- @type DbContext
    local context

    before_each(function()
        test = Model("test", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "name", Types.Text },
            { "active", Types.Int },
        })

        context = Context.new({}, { test })
    end)

    it("marks a materialized entity as unchanged", function()
        local entity = context:_materialize(test, { id = 1, name = "A" })
        assert.equals(State.UNCHANGED, context.changeTracker:getEntry(entity).state)
    end)

    it("marks a changed queried entity as modified", function()
        local entity = context:_materialize(test, { id = 1, name = "A" })
        entity.name = "B"
        assert.equals(State.MODIFIED, context.changeTracker:getEntry(entity).state)
    end)

    it("returns to unchanged when a value is restored", function()
        local entity = context:_materialize(test, { id = 1, name = "A" })
        entity.name = "B"
        entity.name = "A"
        assert.equals(State.UNCHANGED, context.changeTracker:getEntry(entity).state)
    end)

    it("keeps newly-added entities in ADDED state when edited", function()
        local entity = test.new({ name = "A" })
        context.data.test:add(entity)
        entity.name = "B"
        assert.equals(State.ADDED, context.changeTracker:getEntry(entity).state)
    end)

    it("cancels an add followed by remove", function()
        local entity = test.new({ name = "A" })
        context.data.test:add(entity)
        context.data.test:remove(entity)
        assert.is_nil(context.changeTracker:getEntry(entity))
    end)

    it("tracks a field changed from a value to nil", function()
        local entity = context:_materialize(test, { id = 1, name = "A" })
        entity.name = nil
        --- @type EntityEntry
        local entry = context.changeTracker:getEntry(entity)
        assert.equals(State.MODIFIED, entry.state)
        assert.equals("A", entry:getOriginalOrCurrentValue("name"))
    end)

    it("returns to unchanged when a nil-ed field is restored", function()
        local entity = context:_materialize(test, { id = 1, name = "A" })
        entity.name = nil
        entity.name = "A"
        assert.equals(State.UNCHANGED, context.changeTracker:getEntry(entity).state)
    end)

    it("tracks a field that started as SQL NULL and gets a value", function()
        -- name absent from the row entirely == NULL from the DB
        local entity = context:_materialize(test, { id = 1 })
        assert.is_nil(entity.name)
        entity.name = "A"
        local entry = context.changeTracker:getEntry(entity)
        assert.equals(State.MODIFIED, entry.state)
        assert.is_nil(entry:getOriginalOrCurrentValue("name"))
    end)

    it("returns to unchanged when a field is set back to NULL #unset", function()
        local entity = context:_materialize(test, { id = 1 })  -- name starts NULL
        entity.name = "A"
        entity.name = nil
        assert.equals(State.UNCHANGED, context.changeTracker:getEntry(entity).state)
    end)

    it("does not mark an entity modified when set to its current value", function()
        local entity = context:_materialize(test, { id = 1, name = "A" })
        entity.name = "A"  -- same value
        assert.equals(State.UNCHANGED, context.changeTracker:getEntry(entity).state)
    end)

    it("stays modified when only one of several changed fields is restored", function()
        local entity = context:_materialize(test, { id = 1, name = "A", active = 1 })
        entity.name = "B"
        entity.active = 0
        entity.name = "A"  -- restore only this one
        --- @type EntityEntry
        local entry = context.changeTracker:getEntry(entity)
        assert.equals(State.MODIFIED, entry.state)
        assert.is_nil(entry.changedFields.name)
        assert.is_true(entry.changedFields.active)
    end)

    it("clears changed fields after acceptChanges", function()
        local entity = context:_materialize(test, { id = 1, name = "A" })
        entity.name = "B"
        --- @type EntityEntry
        local entry = context.changeTracker:getEntry(entity)
        entry:acceptChanges()
        assert.equals(State.UNCHANGED, entry.state)
        assert.is_nil(next(entry.changedFields))
        assert.is_nil(next(entry.originalValues))
    end)

    it("treats a further edit after acceptChanges as a fresh change", function()
        local entity = context:_materialize(test, { id = 1, name = "A" })
        entity.name = "B"
        context.changeTracker:getEntry(entity):acceptChanges()
        entity.name = "C"
        --- @type EntityEntry
        local entry = context.changeTracker:getEntry(entity)
        assert.equals(State.MODIFIED, entry.state)
        assert.equals("B", entry:getOriginalOrCurrentValue("name"))  -- "B" is now the baseline, not "A"
    end)

    it("returns the same entity instance for a repeated primary key", function()
        local e1 = context:_materialize(test, { id = 1, name = "A" })
        local e2 = context:_materialize(test, { id = 1, name = "A" })
        assert.equals(e1, e2)  -- same table identity, not just equal fields
    end)

    it("returns distinct entities for different primary keys", function()
        local e1 = context:_materialize(test, { id = 1, name = "A" })
        local e2 = context:_materialize(test, { id = 2, name = "B" })
        assert.is_not.equals(e1, e2)
    end)

    it("groups entries by state correctly", function()
        local unchanged = context:_materialize(test, { id = 1, name = "A" })
        local modified = context:_materialize(test, { id = 2, name = "B" })
        modified.name = "C"
        local added = test.new({ name = "D" })
        context.data.test:add(added)

        assert.equals(1, #context.changeTracker:entriesInState(State.UNCHANGED))
        assert.equals(1, #context.changeTracker:entriesInState(State.MODIFIED))
        assert.equals(1, #context.changeTracker:entriesInState(State.ADDED))
    end)

    it("rejects writing to a field that doesn't exist", function()
        local entity = test.new({ name = "A" })
        assert.has_error(function()
            entity.nonexistent = "X"
        end)
    end)

    it("rejects adding an entity of the wrong model to a DataSet", function()
        local other = Model("other", {
            { "id", Types.Int, Constraint.PrimaryKey },
        })
        local entity = other.new({})
        assert.has_error(function()
            context.data.test:add(entity)
        end)
    end)
end)
