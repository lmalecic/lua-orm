---@diagnostic disable: undefined-global, undefined-field

package.path = "./?.lua;./?/init.lua;" .. package.path

local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")
local Context = require("orm.context")
local EntityEntry = require("orm.change-tracking.entity-entry")

describe("model relations", function()
    local Parent
    local Child
    local context

    before_each(function()
        Parent = Model("parent", {
            { "id", Types.Int, Constraint.PrimaryKey },
        })

        Child = Model("child", {
            { "id", Types.Int, Constraint.PrimaryKey },
            {
                "parent",
                Relation.belongsTo("parent", "id", { foreignKey = "parent_ref" }),
                Constraint.NotNull,
            },
        })

        context = Context.new({}, { Child, Parent })
    end)

    it("keeps logical relations separate from physical fields", function()
        local relation = Child.relations.parent

        assert.is_not_nil(relation)
        assert.is_nil(Child.fieldsByName.parent)
        assert.equals("parent_ref", relation.foreignKeyColumn)
        assert.equals(Child.fieldsByName.parent_ref, relation.foreignKeyField)
    end)

    it("exposes include selectors by logical relation name", function()
        local proxy = Child.asRelationProxy().parent

        assert.equals("parent_ref", proxy.fieldName)
        assert.equals("parent", proxy.referenceTableName)
        assert.has_error(function()
            return Child.asRelationProxy().parent_ref
        end)
    end)

    it("generates a foreign-key field using the referenced field type", function()
        local field = Child.fieldsByName.parent_ref

        assert.equals(Types.Int, field.type)
        assert.is_false(field.nullable)
        assert.equals("parent", field.foreignKey.referenceTable)
        assert.equals("id", field.foreignKey.referenceColumn)
    end)

    it("uses the relation and reference column for the default foreign-key name", function()
        local DefaultChild = Model("default_child", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "parent", Relation.belongsTo("parent", "id") },
        })

        Context.new({}, { DefaultChild, Parent })

        assert.is_not_nil(DefaultChild.fieldsByName.parent_id)
        assert.equals("parent_id", DefaultChild.relations.parent.foreignKeyColumn)
    end)

    it("does not create a relation for an old-style foreign-key field", function()
        local Legacy = Model("legacy", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "parent_id", Types.Int, Constraint.ForeignKey("parent", "id") },
        })

        Context.new({}, { Legacy, Parent })

        assert.is_nil(next(Legacy.relations))
        assert.is_not_nil(Legacy.fieldsByName.parent_id.foreignKey)
    end)

    it("sets and tracks the physical foreign key when assigning a relation", function()
        local parent = context:_materialize(Parent, { id = 2 })
        local child = context:_materialize(Child, { id = 10, parent_ref = 1 })

        child.parent = parent

        local entry = context.changeTracker:getEntry(child)
        assert.equals(parent, child.parent)
        assert.equals(2, child.parent_ref)
        assert.equals(EntityEntry.State.MODIFIED, entry.state)
        assert.is_true(entry.changedFields.parent_ref)
        assert.is_nil(entry.changedFields.parent)
    end)

    it("clears a loaded relation when its physical foreign key changes", function()
        local parent = context:_materialize(Parent, { id = 1 })
        local child = context:_materialize(Child, { id = 10, parent_ref = 1 })
        child.parent = parent

        child.parent_ref = 2

        assert.is_nil(child.parent)
        assert.equals(2, child.parent_ref)
    end)

    it("rejects entities from the wrong model", function()
        local Other = Model("other", {
            { "id", Types.Int, Constraint.PrimaryKey },
        })
        local other = Other.new({ id = 1 })
        local child = context:_materialize(Child, { id = 10, parent_ref = 1 })

        assert.has_error(function()
            child.parent = other
        end)
    end)
end)
