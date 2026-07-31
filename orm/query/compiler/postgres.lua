local PostgresCompiler = {}
PostgresCompiler.__index = PostgresCompiler

function PostgresCompiler.new()
    return setmetatable({}, PostgresCompiler)
end

local function quoteIdentifier(name)
    local out = {}
    for part in string.gmatch(name, "[^%.]+") do
        table.insert(out, '"' .. part:gsub('"', '""') .. '"')
    end
    return table.concat(out, ".")
end

function PostgresCompiler:compile(node)
    local params = {}
    local sql = self:_compileNode(node, params)
    return sql, params
end

function PostgresCompiler:compileWhere(node)
    local sql, params = self:compile(node)
    return "WHERE " .. sql, params
end

function PostgresCompiler:_compileNode(node, params)
    assert(type(node) == "table" and type(node.nodeType) == "string", "Invalid AST node")

    if node.nodeType == "member" then
        return quoteIdentifier(node.name)
    end

    if node.nodeType == "constant" then
        table.insert(params, node.value)
        return "$" .. #params
    end

    if node.nodeType == "comparison" then
        if node.right and node.right.nodeType == "constant" and node.right.value == nil then
            local left = self:_compileNode(node.left, params)
            if node.operator == "=" then
                return left .. " IS NULL"
            end
            if node.operator == "<>" then
                return left .. " IS NOT NULL"
            end
        end

        local left = self:_compileNode(node.left, params)
        local right = self:_compileNode(node.right, params)
        return left .. " " .. node.operator .. " " .. right
    end

    if node.nodeType == "logical" then
        local left = self:_compileNode(node.left, params)
        local right = self:_compileNode(node.right, params)
        return "(" .. left .. " " .. node.operator .. " " .. right .. ")"
    end

    error("Unsupported AST node type: " .. tostring(node.nodeType))
end

return PostgresCompiler
