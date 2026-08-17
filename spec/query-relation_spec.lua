---@diagnostic disable: undefined-global, undefined-field

local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")
local Context = require("orm.context")

describe("query relation materialization", function()
    local Parent
    local Child
    local context
    local queryResult
    local compiledFirst

    before_each(function()
        Parent = Model("parent", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "name", Types.Text },
        })

        Child = Model("child", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "label", Types.Text },
            { "parent", Relation.belongsTo("parent", "id") },
        })

        context = Context.new({}, { Child, Parent })
        compiledFirst = false

        context.getCompiler = function()
            return {
                compileSelect = function()
                    return "SELECT", {}
                end,
                compileSelectFirst = function()
                    compiledFirst = true
                    return "SELECT FIRST", {}
                end,
            }
        end

        context.query_array = function()
            return queryResult
        end
    end)

    it("materializes all root entities without includes", function()
        queryResult = {
            { 1, "A", 10 },
            { 2, "B", 20 },
            fields = { "id", "label", "parent_id" },
        }

        local entities = context.data.child:all()

        assert.equals(2, #entities)
        assert.equals(1, entities[1].id)
        assert.equals("A", entities[1].label)
        assert.equals(10, entities[1].parent_id)
        assert.equals(2, entities[2].id)
    end)

    it("splits included columns and attaches the related entity", function()
        queryResult = {
            { 1, "A", 10, 10, "Parent" },
            fields = { "id", "label", "parent_id", "id", "name" },
        }

        local entities = context.data.child:include(function(child)
            return child.parent
        end):all()

        assert.equals(1, #entities)
        assert.equals(10, entities[1].parent.id)
        assert.equals("Parent", entities[1].parent.name)
        assert.equals(10, entities[1].parent_id)
        assert.equals(entities[1].parent, context.changeTracker.identityMap[Parent][10])
    end)

    it("sets an optional relation to nil for an unmatched left join", function()
        local null = {}
        context.connection.client.NULL = null
        queryResult = {
            { 1, "A", null, null, null },
            fields = { "id", "label", "parent_id", "id", "name" },
        }

        local entity = context.data.child:include(function(child)
            return child.parent
        end):first()

        assert.is_true(compiledFirst)
        assert.is_nil(entity.parent)
        assert.is_nil(entity.parent_id)
    end)

    it("returns nil from first when the query has no rows", function()
        queryResult = {
            fields = { "id", "label", "parent_id" },
        }

        assert.is_nil(context.data.child:first())
        assert.is_true(compiledFirst)
    end)

    it("does not register the same include more than once", function()
        local query = context.data.child:include(function(child)
            return child.parent
        end):include(function(child)
            return child.parent
        end)

        assert.equals(1, #query.nodes.include)
    end)

    it("does not replace a locally changed relation with stale joined data", function()
        local oldParent = context:_materialize(Parent, { id = 10, name = "Old" })
        local newParent = context:_materialize(Parent, { id = 20, name = "New" })
        local child = context:_materialize(Child, { id = 1, label = "A", parent_id = 10 })
        child.parent = newParent

        queryResult = {
            { 1, "A", 10, 10, "Old" },
            fields = { "id", "label", "parent_id", "id", "name" },
        }

        local result = context.data.child:include(function(entity)
            return entity.parent
        end):all()

        assert.equals(child, result[1])
        assert.equals(20, child.parent_id)
        assert.equals(newParent, child.parent)
        assert.is_not.equals(oldParent, child.parent)
    end)

    it("rejects a result whose projection does not match the model metadata", function()
        queryResult = {
            { 1, "A" },
            fields = { "id", "label" },
        }

        assert.has_error(function()
            context.data.child:all()
        end, "Query returned 2 columns, but model and include metadata expected 3")
    end)
end)
