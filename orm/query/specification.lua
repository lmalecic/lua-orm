local LogicalNode = require("orm.query.node.logical")
local UnaryNode = require("orm.query.node.unary")

local Specification = {}

function Specification.and_(...)
	return LogicalNode.new(LogicalNode.Operators.AND, ...)
end

function Specification.or_(...)
	return LogicalNode.new(LogicalNode.Operators.OR, ...)
end

function Specification.not_(node)
    if node.__index == UnaryNode and node.op == UnaryNode.Operators.NOT then
        return node.operand
    end

	return UnaryNode.new(UnaryNode.Operators.NOT, node)
end

return Specification
