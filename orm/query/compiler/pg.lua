local FieldProxy = require("orm.query.field-proxy")
local OrderFieldProxy = require("orm.query.order-field-proxy")

local ConstantNode = require("orm.query.node.constant")
local ComparisonNode = require("orm.query.node.comparison")
local LogicalNode = require("orm.query.node.logical")
local UnaryNode = require("orm.query.node.unary")
local OrderNode = require("orm.query.node.order")

local Alter = require("orm.migrations.alter")

local Modifiers = {
    PRIMARY_KEY = "PRIMARY KEY",
    GENERATED_AS_IDENTITY = "GENERATED %s AS IDENTITY",
    NOT_NULL = "NOT NULL",
    UNIQUE = "UNIQUE",
    DEFAULT = "DEFAULT %s",
    REFERENCES = "REFERENCES %s(%s)"
}

local Clauses = {
    SELECT = "SELECT",
    FROM = "FROM",
    WHERE = "WHERE",
    ORDER_BY = "ORDER BY",

    CREATE_TABLE = "CREATE TABLE %s (%s);",
    DROP_TABLE = "DROP TABLE %s;",
    ALTER_TABLE = "ALTER TABLE %s %s;",

    BEGIN = "BEGIN;",
    COMMIT = "COMMIT;",
    ROLLBACK = "ROLLBACK;",
}

local Syntax = {
    ALL_COLUMNS = "*"
}

local Alterations = {
    ADD_COLUMN = "ADD COLUMN %s",
    DROP_COLUMN = "DROP COLUMN %s",
    RENAME_COLUMN = "RENAME COLUMN %s TO %s",

    ADD_CONSTRAINT = "ADD CONSTRAINT %s %s (%s)",
    ADD_FOREIGN_KEY_CONSTRAINT = "ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s(%s)",
    DROP_CONSTRAINT = "DROP CONSTRAINT %s",
}

local ConstraintTypes = {
    [Alter.ConstraintTypes.PRIMARY_KEY] = "PRIMARY KEY",
    [Alter.ConstraintTypes.UNIQUE] = "UNIQUE",
}

local Operators = {
    [LogicalNode.Operators.AND] = "AND",
    [LogicalNode.Operators.OR] = "OR",
    [ComparisonNode.Operators.EQUALS] = "=",
    [ComparisonNode.Operators.NOT_EQUALS] = "<>",
    [ComparisonNode.Operators.GREATER_THAN] = ">",
    [ComparisonNode.Operators.GREATER_THAN_OR_EQUAL] = ">=",
    [ComparisonNode.Operators.LESS_THAN] = "<",
    [ComparisonNode.Operators.LESS_THAN_OR_EQUAL] = "<=",
    [ComparisonNode.Operators.LIKE] = "LIKE",
    [UnaryNode.Operators.IS_NULL] = "IS NULL",
    [UnaryNode.Operators.IS_NOT_NULL] = "IS NOT NULL",
    [UnaryNode.Operators.NOT] = "NOT",
}

local OrderDirection = {
    [OrderNode.Direction.ASC] = "ASC",
    [OrderNode.Direction.DESC] = "DESC",
}

local NameFormats = {
    PRIMARY_KEY = "%s_pkey",
    UNIQUE_KEY = "%s_%s_key",
}

local PgCompiler = {}
PgCompiler.__index = PgCompiler

PgCompiler.MAINTENANCE_DATABASE = "postgres"
PgCompiler.DATABASE_TABLE = "pg_database"

function PgCompiler.new(postgres)
    local self = setmetatable({}, PgCompiler)
    self.params = {}
    self.postgres = postgres
    return self
end

-- Transactions

function PgCompiler:compileBeginTransaction()
    return Clauses.BEGIN
end

function PgCompiler:compileCommitTransaction()
    return Clauses.COMMIT
end

function PgCompiler:compileRollbackTransaction()
    return Clauses.ROLLBACK
end

-- Tables

--- @param tableName string
--- @param fields Field[]
--- @return string
function PgCompiler:compileCreateTable(tableName, fields)
    local columns = {}

    if #fields > 0 then
        for _, field in ipairs(fields) do
            print(field.name, field.autoIncrement)
            table.insert(columns, self:compileColumn(field))
        end
    end

    return Clauses.CREATE_TABLE:format(self.postgres:escape_identifier(tableName), table.concat(columns, ", "))
end

--- @param name string
function PgCompiler:compileDropTable(name)
    return Clauses.DROP_TABLE:format(self.postgres:escape_identifier(name))
end

function PgCompiler:compileAlterTable(tableName, alterations)
    local alters = {}

    for _, alteration in ipairs(alterations) do
        table.insert(alters, self:compileAlteration(alteration))
    end

    return Clauses.ALTER_TABLE:format(self.postgres:escape_identifier(tableName), table.concat(alters, ", "))
end

--- @param alteration Alteration
function PgCompiler:compileAlterationConstraint(alteration)
    local type = ConstraintTypes[alteration.type]
    assert(type, "Unsupported constraint type: " .. tostring(alteration.type))

    return type
end

--- @param alteration Alteration
function PgCompiler:compileAlteration(alteration)
    if alteration.kind == Alter.Kinds.ADD_COLUMN then
        return Alterations.ADD_COLUMN:format(self:compileColumn(alteration.field))
    elseif alteration.kind == Alter.Kinds.DROP_COLUMN then
        return Alterations.DROP_COLUMN:format(self.postgres:escape_identifier(alteration.name))
    elseif alteration.kind == Alter.Kinds.ADD_CONSTRAINT then
        if alteration.type == Alter.ConstraintTypes.FOREIGN_KEY then
            return Alterations.ADD_FOREIGN_KEY_CONSTRAINT:format(
                self.postgres:escape_identifier(alteration.name),
                self.postgres:escape_identifier(alteration.columnName),
                self.postgres:escape_identifier(alteration.referenceTable),
                self.postgres:escape_identifier(alteration.referenceColumn)
            )
        end

        return Alterations.ADD_CONSTRAINT:format(self.postgres:escape_identifier(alteration.name), self:compileAlterationConstraint(alteration), self.postgres:escape_identifier(alteration.columnName))
    elseif alteration.kind == Alter.Kinds.DROP_CONSTRAINT then
        return Alterations.DROP_CONSTRAINT:format(self.postgres:escape_identifier(alteration.name))
    end

    error("Unsupported alteration type!")
end

function PgCompiler:_addParam(value)
    table.insert(self.params, value)
    return "$" .. tostring(#self.params)
end

function PgCompiler:_compileWhereNode(node)
    assert(type(node) == "table", "node must be a table")

    if node.__index == FieldProxy then
        return string.format("%s.%s", self.postgres:escape_identifier(node.table),
            self.postgres:escape_identifier(node.column))
    end

    if node.__index == ConstantNode then
        return self:_addParam(node.value)
    end

    if node.__index == ComparisonNode then
        local op = Operators[node.op]
        assert(op, "unsupported comparison operator: " .. tostring(node.op))
        return string.format("(%s %s %s)", self:_compileWhereNode(node.left), op, self:_compileWhereNode(node.right))
    end

    if node.__index == LogicalNode then
        local op = Operators[node.op]
        assert(op, "unsupported logical operator: " .. tostring(node.op))

        -- N-ary iteration over node.children (or node.nodes)
        local parts = {}
        for i, child in ipairs(node.children) do
            parts[i] = self:_compileWhereNode(child)
        end

        local delimiter = string.format(" %s ", op)
        return string.format("(%s)", table.concat(parts, delimiter))
    end

    if node.__index == UnaryNode then
        local op = Operators[node.op]
        assert(op, "unsupported unary operator: " .. tostring(node.op))

        local targetSql = self:_compileWhereNode(node.operand)
        local first = node.opFirst and op or targetSql
        local second = not node.opFirst and op or targetSql

        return string.format("(%s %s)", first, second)
    end

    error("Unsupported node type in WHERE clause")
end

function PgCompiler:_compileOrderByNode(node)
    assert(type(node) == "table", "node must be a table")

    if node.__index == OrderFieldProxy then
        return string.format("%s.%s", self.postgres:escape_identifier(node.table),
            self.postgres:escape_identifier(node.column))
    end

    if node.__index == OrderNode then
        local fieldSql = self:_compileOrderByNode(node.fieldProxy)
        local direction = OrderDirection[node.direction]
        assert(direction ~= nil, "Unsupported order direction: " .. tostring(node.direction))

        return string.format("%s %s", fieldSql, direction)
    end

    if node.__index == ConstantNode then
        error("Unsupported node type in ORDER BY clause; ConstantNode is not supported due to its ambiguous nature")
    end

    error("Unsupported node type in ORDER BY clause")
end

function PgCompiler:compileType(typeInstance)
    -- atm no multi-provider support, formatting is buried in the type instance
    return typeInstance:toSql()
end

--- @param field Field
function PgCompiler:compileDefault(field)
    -- atm no multi-provider support, formatting is buried in the type instance
    if type(field.default) ~= "table" then
        return self.postgres:escape_literal(field.default)
    end

    return field.type:formatDefault(field.default)
end

--- @param field Field
function PgCompiler:compileColumn(field)
    local fragments = { self.postgres:escape_identifier(field.name), self:compileType(field.type) }

    if field.autoIncrement then
        assert(field.identityMode, "Auto-increment fields must have an identity mode in PostgreSQL")
        table.insert(fragments, Modifiers.GENERATED_AS_IDENTITY:format(field.identityMode))
    end

    if not field.nullable then
        table.insert(fragments, Modifiers.NOT_NULL)
    end

    if field.unique then
        table.insert(fragments, Modifiers.UNIQUE)
    end

    if field.default ~= nil and not field.autoIncrement then
        table.insert(fragments, Modifiers.DEFAULT:format(self:compileDefault(field)))
    end

    if field.primaryKey then
        table.insert(fragments, Modifiers.PRIMARY_KEY)
    end

    if field.foreignKey then
        table.insert(fragments, Modifiers.REFERENCES:format(
            self.postgres:escape_identifier(field.foreignKey.referenceTable),
            self.postgres:escape_identifier(field.foreignKey.referenceColumn)))
    end

    return table.concat(fragments, " ")
end

--- @return string, { [number]: any }
function PgCompiler:compileSelect(query)
    -- SELECT * FROM [tableName]
    -- WHERE ...
    -- ORDER BY ...

    local fragments = { Clauses.SELECT, Syntax.ALL_COLUMNS, Clauses.FROM, self.postgres:escape_identifier(query
    .modelClass.tableName) }

    if query.nodes.where and #query.nodes.where > 0 then
        table.insert(fragments, Clauses.WHERE)
        for _, node in ipairs(query.nodes.where) do
            table.insert(fragments, self:_compileWhereNode(node))
        end
    end

    if query.nodes.orderBy and #query.nodes.orderBy > 0 then
        table.insert(fragments, Clauses.ORDER_BY)
        local orderClauses = {}
        for _, node in ipairs(query.nodes.orderBy) do
            table.insert(orderClauses, self:_compileOrderByNode(node))
        end
        table.insert(fragments, table.concat(orderClauses, ", "))
    end

    return table.concat(fragments, " "), self.params
end

-- Migrations

--- @param query string[]
function PgCompiler:compileMigration(query)
    return table.concat(query, "; ") .. ";"
end

function PgCompiler:compileDropConstraint(name)
    return Alterations.DROP_CONSTRAINT:format(self.postgres:escape_identifier(name))
end

function PgCompiler:getPrimaryKeyConstraintName(tableName)
    return NameFormats.PRIMARY_KEY:format(tableName)
end

function PgCompiler:getUniqueKeyConstraintName(tableName, columnName)
    return NameFormats.UNIQUE_KEY:format(tableName, columnName)
end

return PgCompiler
