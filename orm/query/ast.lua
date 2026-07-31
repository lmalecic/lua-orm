local Ast = {}

Ast.NodeType = {
    CONSTANT = "constant",
    MEMBER = "member",
    COMPARISON = "comparison",
    LOGICAL = "logical",
}

Ast.ComparisonOperator = {
    EQ = "=",
    NE = "<>",
    GT = ">",
    GTE = ">=",
    LT = "<",
    LTE = "<=",
}

Ast.LogicalOperator = {
    AND = "AND",
    OR = "OR",
}

local Expression = {}
Expression.__index = Expression

local function asExpression(value)
    if Ast.isNode(value) then
        return value
    end
    return Ast.constant(value)
end

function Expression:eq(value)
    return Ast.comparison(Ast.ComparisonOperator.EQ, self, asExpression(value))
end

function Expression:ne(value)
    return Ast.comparison(Ast.ComparisonOperator.NE, self, asExpression(value))
end

function Expression:gt(value)
    return Ast.comparison(Ast.ComparisonOperator.GT, self, asExpression(value))
end

function Expression:gte(value)
    return Ast.comparison(Ast.ComparisonOperator.GTE, self, asExpression(value))
end

function Expression:lt(value)
    return Ast.comparison(Ast.ComparisonOperator.LT, self, asExpression(value))
end

function Expression:lte(value)
    return Ast.comparison(Ast.ComparisonOperator.LTE, self, asExpression(value))
end

function Expression:and_(other)
    return Ast.logical(Ast.LogicalOperator.AND, self, asExpression(other))
end

function Expression:or_(other)
    return Ast.logical(Ast.LogicalOperator.OR, self, asExpression(other))
end

local function node(nodeType, payload)
    payload.nodeType = nodeType
    return setmetatable(payload, Expression)
end

function Ast.constant(value)
    return node(Ast.NodeType.CONSTANT, { value = value })
end

function Ast.member(name)
    assert(type(name) == "string" and name ~= "", "Member name must be a non-empty string")
    return node(Ast.NodeType.MEMBER, { name = name })
end

function Ast.comparison(operator, left, right)
    return node(Ast.NodeType.COMPARISON, {
        operator = operator,
        left = left,
        right = right,
    })
end

function Ast.logical(operator, left, right)
    return node(Ast.NodeType.LOGICAL, {
        operator = operator,
        left = left,
        right = right,
    })
end

function Ast.isNode(value)
    return type(value) == "table" and type(value.nodeType) == "string"
end

return Ast
