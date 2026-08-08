local FieldProxy = require("orm.query.field-proxy")
local OrderFieldProxy = require("orm.query.order-field-proxy")

local ConstantNode = require("orm.query.node.constant")
local ComparisonNode = require("orm.query.node.comparison")
local LogicalNode = require("orm.query.node.logical")
local UnaryNode = require("orm.query.node.unary")
local OrderNode = require("orm.query.node.order")

local PgCompiler = {}
PgCompiler.__index = PgCompiler

local Keywords = {
    SELECT = "SELECT",
    FROM = "FROM",
    WHERE = "WHERE",
    ORDER_BY = "ORDER BY"
}

local OrderDirection = {
    [OrderNode.Direction.ASC] = "ASC",
    [OrderNode.Direction.DESC] = "DESC",
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
        return string.format("%s.%s", self.postgres:escape_identifier(node.table), self.postgres:escape_identifier(node.column))
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

--- @return string, { [number]: any }
function PgCompiler:compileSelect(query)
    -- SELECT * FROM [tableName]
    -- WHERE ...
    -- ORDER BY ...

    local clauses = { Keywords.SELECT, Syntax.ALL_COLUMNS, Keywords.FROM, self.postgres:escape_identifier(query.modelClass.tableName) }

    if query.nodes.where and #query.nodes.where > 0 then
        table.insert(clauses, Keywords.WHERE)
        for _, node in ipairs(query.nodes.where) do
            table.insert(clauses, self:_compileWhereNode(node))
        end
    end

    if query.nodes.orderBy and #query.nodes.orderBy > 0 then
        table.insert(clauses, Keywords.ORDER_BY)
        local orderClauses = {}
        for _, node in ipairs(query.nodes.orderBy) do
            table.insert(orderClauses, self:_compileOrderByNode(node))
        end
        table.insert(clauses, table.concat(orderClauses, ", "))
    end

    return table.concat(clauses, " "), self.params
end

return PgCompiler
