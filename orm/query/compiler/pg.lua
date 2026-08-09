local FieldProxy = require("orm.query.field-proxy")
local OrderFieldProxy = require("orm.query.order-field-proxy")

local ConstantNode = require("orm.query.node.constant")
local ComparisonNode = require("orm.query.node.comparison")
local LogicalNode = require("orm.query.node.logical")
local UnaryNode = require("orm.query.node.unary")
local OrderNode = require("orm.query.node.order")

local Modifiers = {
    PRIMARY_KEY = "PRIMARY KEY",
    GENERATED_AS_IDENTITY = "GENERATED %s AS IDENTITY",
    NOT_NULL = "NOT NULL",
    UNIQUE = "UNIQUE",
    DEFAULT = "DEFAULT %s"
}

local Clauses = {
    SELECT = "SELECT",
    FROM = "FROM",
    WHERE = "WHERE",
    ORDER_BY = "ORDER BY",
    CREATE_TABLE = "CREATE TABLE",
    DROP_TABLE = "DROP TABLE",
}

local Syntax = {
    ALL_COLUMNS = "*"
}

local Operators = {
    [LogicalNode.Operators.AND] = "AND",
    [LogicalNode.Operators.OR] = "OR",
    [ComparisonNode.Operators.EQUALS] = "=",
    [ComparisonNode.Operators.NOT_EQUALS] = "<>",
    [ComparisonNode.Operators.GREATER_THAN] = ">",
    [ComparisonNode.Operators.GREATER_THAN_OR_EQUAL] = ">=",
    [ComparisonNode.Operators.LESS_THAN] = "<",
    [ComparisonNode.Operators.LESS_THAN_OR_EQUAL] = "<=",
    [ComparisonNode.Operators.LIKE] = "LIKE",
    [UnaryNode.Operators.IS_NULL] = "IS NULL",
    [UnaryNode.Operators.IS_NOT_NULL] = "IS NOT NULL",
    [UnaryNode.Operators.NOT] = "NOT",
}

local OrderDirection = {
    [OrderNode.Direction.ASC] = "ASC",
    [OrderNode.Direction.DESC] = "DESC",
}

local PgCompiler = {}
PgCompiler.__index = PgCompiler

PgCompiler.MAINTENANCE_DATABASE = "postgres"
PgCompiler.DATABASE_TABLE = "pg_database"

function PgCompiler.new(postgres)
    local self = setmetatable({}, PgCompiler)
    self.params = {}
    self.postgres = postgres
    return self
end

function PgCompiler:_addParam(value)
    table.insert(self.params, value)
    return "$" .. tostring(#self.params)
end

function PgCompiler:_compileWhereNode(node)
    assert(type(node) == "table", "node must be a table")

    if node.__index == FieldProxy then
        return string.format("%s.%s", self.postgres:escape_identifier(node.table),
            self.postgres:escape_identifier(node.column))
    end

    if node.__index == ConstantNode then
        return self:_addParam(node.value)
    end

    if node.__index == ComparisonNode then
        local op = Operators[node.op]
        assert(op, "unsupported comparison operator: " .. tostring(node.op))
        return string.format("(%s %s %s)", self:_compileWhereNode(node.left), op, self:_compileWhereNode(node.right))
    end

    if node.__index == LogicalNode then
        local op = Operators[node.op]
        assert(op, "unsupported logical operator: " .. tostring(node.op))

        -- N-ary iteration over node.children (or node.nodes)
        local parts = {}
        for i, child in ipairs(node.children) do
            parts[i] = self:_compileWhereNode(child)
        end

        local delimiter = string.format(" %s ", op)
        return string.format("(%s)", table.concat(parts, delimiter))
    end

    if node.__index == UnaryNode then
        local op = Operators[node.op]
        assert(op, "unsupported unary operator: " .. tostring(node.op))

        local targetSql = self:_compileWhereNode(node.operand)
        local first = node.opFirst and op or targetSql
        local second = not node.opFirst and op or targetSql

        return string.format("(%s %s)", first, second)
    end

    error("Unsupported node type in WHERE clause")
end

function PgCompiler:_compileOrderByNode(node)
    assert(type(node) == "table", "node must be a table")

    if node.__index == OrderFieldProxy then
        return string.format("%s.%s", self.postgres:escape_identifier(node.table),
            self.postgres:escape_identifier(node.column))
    end

    if node.__index == OrderNode then
        local fieldSql = self:_compileOrderByNode(node.fieldProxy)
        local direction = OrderDirection[node.direction]
        assert(direction ~= nil, "Unsupported order direction: " .. tostring(node.direction))

        return string.format("%s %s", fieldSql, direction)
    end

    if node.__index == ConstantNode then
        error("Unsupported node type in ORDER BY clause; ConstantNode is not supported due to its ambiguous nature")
    end

    error("Unsupported node type in ORDER BY clause")
end

function PgCompiler:compileType(typeInstance)
    -- atm no multi-provider support, formatting is buried in the type instance
    return typeInstance:toSql()
end

function PgCompiler:compileDefault(field)
    -- atm no multi-provider support, formatting is buried in the type instance
    if type(field.defaultValue) == "table" and field.defaultValue.__raw then
        return field.defaultValue.value
    end

    return field.type:formatDefault(field.defaultValue)
end

function PgCompiler:compileColumn(field)
    local fragments = { self.postgres:escape_identifier(field.name), self:compileType(field.type) }

    if self.autoIncrement then
        table.insert(fragments, string.format(Modifiers.GENERATED_AS_IDENTITY, field.identityMode))
    end

    if not self.nullable then
        table.insert(fragments, Modifiers.NOT_NULL)
    end

    if self.isUnique then
        table.insert(fragments, Modifiers.UNIQUE)
    end

    if self.defaultValue ~= nil and not self.autoIncrement then
        table.insert(fragments, string.format(Modifiers.DEFAULT, self:compileDefault(field)))
    end

    if self.isPrimaryKey then
        table.insert(fragments, Modifiers.PRIMARY_KEY)
    end

    return table.concat(fragments, " ")
end

--- @param model ModelClass
--- @return string
function PgCompiler:compileCreateTable(model)
    local fragments = { Clauses.CREATE_TABLE, self.postgres:escape_identifier(model.tableName) }

    if #model.fields > 0 then
        table.insert(fragments, "(")

        local columns = {}
        for _, field in ipairs(model.fields) do
            table.insert(columns, self:compileColumn(field))
        end

        table.insert(fragments, table.concat(columns, ", "))
        table.insert(fragments, ")")
    end

    return table.concat(fragments, " ")
end

function PgCompiler:compileDropTable(model)
    local fragments = { Clauses.DROP_TABLE, self.postgres:escape_identifier(model.tableName) }
    return table.concat(fragments, " ")
end

--- @return string, { [number]: any }
function PgCompiler:compileSelect(query)
    -- SELECT * FROM [tableName]
    -- WHERE ...
    -- ORDER BY ...

    local fragments = { Clauses.SELECT, Syntax.ALL_COLUMNS, Clauses.FROM, self.postgres:escape_identifier(query.modelClass.tableName) }

    if query.nodes.where and #query.nodes.where > 0 then
        table.insert(fragments, Clauses.WHERE)
        for _, node in ipairs(query.nodes.where) do
            table.insert(fragments, self:_compileWhereNode(node))
        end
    end

    if query.nodes.orderBy and #query.nodes.orderBy > 0 then
        table.insert(fragments, Clauses.ORDER_BY)
        local orderClauses = {}
        for _, node in ipairs(query.nodes.orderBy) do
            table.insert(orderClauses, self:_compileOrderByNode(node))
        end
        table.insert(fragments, table.concat(orderClauses, ", "))
    end

    return table.concat(fragments, " "), self.params
end

return PgCompiler
