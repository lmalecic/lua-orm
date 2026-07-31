local Ast = require("orm.query.ast")
local Builder = require("orm.query.builder")
local PostgresCompiler = require("orm.query.compiler.postgres")

local Query = {
    Ast = Ast,
    Builder = Builder,
    Compiler = {
        Postgres = PostgresCompiler,
    },
    col = Builder.col,
    val = Builder.val,
}

function Query.compileWhere(expression)
    local compiler = PostgresCompiler.new()
    return compiler:compileWhere(expression)
end

return Query
