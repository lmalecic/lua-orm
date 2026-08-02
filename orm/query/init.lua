local LogicalNode = require("orm.query.node.logical")
local UnaryNode = require("orm.query.node.unary")

local Query = {}

function Query.and_(...)
	return LogicalNode.new(LogicalNode.Operators.AND, ...)
end

function Query.or_(...)
	return LogicalNode.new(LogicalNode.Operators.OR, ...)
end

function Query.not_(node)
    if node.__index == UnaryNode and node.op == UnaryNode.Operators.NOT then
        return node.operand
    end

	return UnaryNode.new(UnaryNode.Operators.NOT, node)
end

return Query
