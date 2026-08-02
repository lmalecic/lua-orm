local UnaryNode = {}
UnaryNode.__index = UnaryNode

UnaryNode.Operators = {
    IS_NULL = "IS_NULL",
    IS_NOT_NULL = "IS_NOT_NULL",
	NOT = "NOT",
}

function UnaryNode.new(operand, op)
	assert(UnaryNode.Operators[op], "Invalid operator: " .. op)
	return setmetatable({
		operand = operand,
		op = op,
	}, UnaryNode)
end

return UnaryNode
