local ComparisonNode = {}
ComparisonNode.__index = ComparisonNode

ComparisonNode.Operators = {
    EQUALS = "EQUALS",
    NOT_EQUALS = "NOT_EQUALS",
    GREATER_THAN = "GREATER_THAN",
    GREATER_THAN_OR_EQUAL = "GREATER_THAN_OR_EQUAL",
    LESS_THAN = "LESS_THAN",
    LESS_THAN_OR_EQUAL = "LESS_THAN_OR_EQUAL",
    IN = "IN",
    NOT_IN = "NOT IN",
    LIKE = "LIKE",
    NOT_LIKE = "NOT LIKE",
    ILIKE = "ILIKE",
    NOT_ILIKE = "NOT ILIKE",
}

function ComparisonNode.new(left, op, right)
	assert(ComparisonNode.Operators[op], "Invalid operator: " .. op)
	return setmetatable({
		left = left,
		op = op,
		right = right,
	}, ComparisonNode)
end

return ComparisonNode
