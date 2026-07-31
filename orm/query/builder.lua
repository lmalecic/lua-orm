local Ast = require("orm.query.ast")

local Builder = {}

function Builder.col(name)
    return Ast.member(name)
end

function Builder.val(value)
    return Ast.constant(value)
end

function Builder.and_(left, right)
    return left:and_(right)
end

function Builder.or_(left, right)
    return left:or_(right)
end

return Builder
