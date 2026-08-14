---@diagnostic disable: undefined-global, undefined-field

package.path = "./?.lua;./?/init.lua;" .. package.path

local PgCompiler = require("orm.query.compiler.pg")
local FieldProxy = require("orm.query.proxy.field")
local OrderFieldProxy = require("orm.query.proxy.order-field")
local RelationFieldProxy = require("orm.query.proxy.relation-field")

describe("PostgreSQL query compiler", function()
    local postgres

    before_each(function()
        postgres = {
            NULL = {},
            escape_identifier = function(_, identifier)
                return '"' .. identifier .. '"'
            end,
        }
    end)

    local function queryWith(include)
        return {
            modelClass = { tableName = "child" },
            nodes = {
                include = include,
                where = { FieldProxy.new("child", "label"):equals("A") },
                orderBy = { OrderFieldProxy.new("child", "id"):desc() },
            },
        }
    end

    local function parentInclude()
        return RelationFieldProxy.new("child", "parent", "parent_id", "parent", "id", false)
    end

    it("keeps includes outside the limited root query for first", function()
        local compiler = PgCompiler.new(postgres)
        local sql, params = compiler:compileSelectFirst(queryWith({ parentInclude() }))

        assert.equals('SELECT * FROM (SELECT * FROM "child" WHERE ("child"."label" = $1) ORDER BY "child"."id" DESC LIMIT 1) AS "child" LEFT JOIN "parent" AS "__orm_include_1" ON "child"."parent_id" = "__orm_include_1"."id"', sql)
        assert.same({ "A" }, params)
    end)

    it("preserves select compilation for all", function()
        local compiler = PgCompiler.new(postgres)
        local sql, params = compiler:compileSelect(queryWith({ parentInclude() }))

        assert.equals('SELECT * FROM "child" LEFT JOIN "parent" AS "__orm_include_1" ON "child"."parent_id" = "__orm_include_1"."id" WHERE ("child"."label" = $1) ORDER BY "child"."id" DESC', sql)
        assert.same({ "A" }, params)
    end)

    it("aliases every include independently", function()
        local compiler = PgCompiler.new(postgres)
        local first = RelationFieldProxy.new("child", "mother", "mother_id", "parent", "id", false)
        local second = RelationFieldProxy.new("child", "father", "father_id", "parent", "id", false)
        local sql = compiler:compileSelect(queryWith({ first, second }))

        assert.is_truthy(sql:find('LEFT JOIN "parent" AS "__orm_include_1" ON "child"."mother_id" = "__orm_include_1"."id"', 1, true))
        assert.is_truthy(sql:find('LEFT JOIN "parent" AS "__orm_include_2" ON "child"."father_id" = "__orm_include_2"."id"', 1, true))
    end)

    it("appends limit normally when first has no includes", function()
        local compiler = PgCompiler.new(postgres)
        local sql, params = compiler:compileSelectFirst(queryWith(nil))

        assert.equals('SELECT * FROM "child" WHERE ("child"."label" = $1) ORDER BY "child"."id" DESC LIMIT 1', sql)
        assert.same({ "A" }, params)
    end)
end)
