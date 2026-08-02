local FieldProxy = require("orm.query.field-proxy")
local ConstantNode = require("orm.query.node.constant")
local ComparisonNode = require("orm.query.node.comparison")
local LogicalNode = require("orm.query.node.logical")
local UnaryNode = require("orm.query.node.unary")

local PgCompiler = {}
PgCompiler.__index = PgCompiler

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

function PgCompiler.new()
    local self = setmetatable({}, PgCompiler)
    self.params = {}
    return self
end

function PgCompiler:_addParam(value)
    table.insert(self.params, value)
    return "$" .. tostring(#self.params)
end

function PgCompiler:_compileNode(node)
	assert(type(node) == "table", "node must be a table")

    if node.__index == FieldProxy then
        return string.format('"%s"."%s"', node.table, node.column)
    end

    if node.__index == ConstantNode then
        return self:_addParam(node.value)
    end

    if node.__index == ComparisonNode then
        local op = Operators[node.op]
        assert(op, "unsupported comparison operator: " .. tostring(node.op))
        return string.format("(%s %s %s)", self:_compileNode(node.left), op, self:_compileNode(node.right))
    end

    if node.__index == LogicalNode then
        local op = Operators[node.op]
        assert(op, "unsupported logical operator: " .. tostring(node.op))

        -- N-ary iteration over node.children (or node.nodes)
        local parts = {}
        for i, child in ipairs(node.children) do
            parts[i] = self:_compileNode(child)
        end

        local delimiter = string.format(" %s ", op)
        return string.format("(%s)", table.concat(parts, delimiter))
    end

    if node.__index == UnaryNode then
    	local op = Operators[node.op]
        assert(op, "unsupported unary operator: " .. tostring(node.op))

        local targetSql = self:_compileNode(node.operand)
        local first = node.opFirst and op or targetSql
        local second = not node.opFirst and op or targetSql

        return string.format("(%s %s)", first, second)
    end

    error("Unsupported node type!")
end

function PgCompiler:compile(node)
	return self:_compileNode(node), self.params
end

return PgCompiler
