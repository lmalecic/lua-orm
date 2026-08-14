local ConstantNode = require("orm.query.node.constant")
local ComparisonNode = require("orm.query.node.comparison")
local LogicalNode = require("orm.query.node.logical")
local UnaryNode = require("orm.query.node.unary")

--- @class FieldProxy
--- @field table string
--- @field column string
local FieldProxy = {}
FieldProxy.__index = FieldProxy

local function isNode(value)
    return value.__index == ConstantNode
        or value.__index == ComparisonNode
        or value.__index == LogicalNode
        or value.__index == UnaryNode
end

local function toNode(value)
    if type(value) == "table" and (isNode(value) or value.__index == FieldProxy) then
        return value
    end

    return ConstantNode.new(value)
end

function FieldProxy.new(tableName, columnName)
    return setmetatable({
        table = tableName,
        column = columnName
    }, FieldProxy)
end

function FieldProxy:equals(value)
	return ComparisonNode.new(self, ComparisonNode.Operators.EQUALS, toNode(value))
end

function FieldProxy:notEquals(value)
	return ComparisonNode.new(self, ComparisonNode.Operators.NOT_EQUALS, toNode(value))
end

function FieldProxy:greaterThan(value)
	return ComparisonNode.new(self, ComparisonNode.Operators.GREATER_THAN, toNode(value))
end

function FieldProxy:greaterThanOrEqual(value)
	return ComparisonNode.new(self, ComparisonNode.Operators.GREATER_THAN_OR_EQUAL, toNode(value))
end

function FieldProxy:lessThan(value)
	return ComparisonNode.new(self, ComparisonNode.Operators.LESS_THAN, toNode(value))
end

function FieldProxy:lessThanOrEqual(value)
	return ComparisonNode.new(self, ComparisonNode.Operators.LESS_THAN_OR_EQUAL, toNode(value))
end

function FieldProxy:isIn(list)
    return ComparisonNode.new(self, ComparisonNode.Operators.IN, toNode(list))
end

function FieldProxy:notIn(list)
	return ComparisonNode.new(self, ComparisonNode.Operators.NOT_IN, toNode(list))
end

function FieldProxy:like(pattern)
	return ComparisonNode.new(self, ComparisonNode.Operators.LIKE, toNode(pattern))
end

function FieldProxy:notLike(pattern)
	return ComparisonNode.new(self, ComparisonNode.Operators.NOT_LIKE, toNode(pattern))
end

function FieldProxy:isNull()
	return UnaryNode.new(self, UnaryNode.Operators.IS_NULL)
end

function FieldProxy:notNull()
    return UnaryNode.new(self, UnaryNode.Operators.IS_NOT_NULL)
end

return FieldProxy
