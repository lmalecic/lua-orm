local LogicalNode = {}
LogicalNode.__index = LogicalNode

LogicalNode.Operators = {
    AND = "AND",
	OR = "OR"
}

function LogicalNode.new(op, ...)
	assert(LogicalNode.Operators[op], "Invalid operator: " .. tostring(op))
	return setmetatable({
        op = op,
		children = { ... }
	}, LogicalNode)
end

return LogicalNode
