local Relation = {}

--- @enum RelationKind
Relation.Kinds = {
    BELONGS_TO = "BELONGS_TO",
    HAS_ONE = "HAS_ONE",
    HAS_MANY = "HAS_MANY",
}

--- @class BelongsToDefinition
--- @field kind "BELONGS_TO"
--- @field referenceTable string
--- @field referenceColumn string
--- @field foreignKeyColumn string?

--- @class InverseRelationDefinition
--- @field kind "HAS_ONE" | "HAS_MANY"
--- @field referenceTable string
--- @field targetForeignKeyColumn string
--- @field localColumn string?

--- @alias RelationDefinition BelongsToDefinition | InverseRelationDefinition
local RelationDefinition = {}
RelationDefinition.__index = RelationDefinition

--- @param referenceTable string
--- @param referenceColumn string
--- @param options table?
--- @return RelationDefinition
function Relation.belongsTo(referenceTable, referenceColumn, options)
    assert(type(referenceTable) == "string" and referenceTable ~= "",
        "Relation.belongsTo() expects a non-empty reference table name; got " .. tostring(referenceTable))
    assert(type(referenceColumn) == "string" and referenceColumn ~= "",
        "Relation.belongsTo() expects a non-empty reference column name; got " .. tostring(referenceColumn))

    options = options or {}

    assert(type(options) == "table",
        "Relation.belongsTo() expects an optional options table; got " .. tostring(options))

    if options.foreignKey ~= nil then
        assert(type(options.foreignKey) == "string" and options.foreignKey ~= "",
            "Relation.belongsTo() option 'foreignKey' must be a non-empty string; got " .. tostring(options.foreignKey))
    end

    return setmetatable({
        kind = Relation.Kinds.BELONGS_TO,
        referenceTable = referenceTable,
        referenceColumn = referenceColumn,
        foreignKeyColumn = options.foreignKey
    }, RelationDefinition)
end

local function inverse(kind, apiName, referenceTable, targetForeignKeyColumn, options)
    assert(type(referenceTable) == "string" and referenceTable ~= "",
        apiName .. " expects a non-empty reference table name; got " .. tostring(referenceTable))
    assert(type(targetForeignKeyColumn) == "string" and targetForeignKeyColumn ~= "",
        apiName .. " expects a non-empty target foreign-key column name; got " ..
            tostring(targetForeignKeyColumn))

    options = options or {}
    assert(type(options) == "table",
        apiName .. " expects an optional options table; got " .. tostring(options))

    if options.localColumn ~= nil then
        assert(type(options.localColumn) == "string" and options.localColumn ~= "",
            apiName .. " option 'localColumn' must be a non-empty string; got " ..
                tostring(options.localColumn))
    end

    return setmetatable({
        kind = kind,
        referenceTable = referenceTable,
        targetForeignKeyColumn = targetForeignKeyColumn,
        localColumn = options.localColumn,
    }, RelationDefinition)
end

--- @param referenceTable string
--- @param targetForeignKeyColumn string
--- @param options table?
--- @return RelationDefinition
function Relation.hasOne(referenceTable, targetForeignKeyColumn, options)
    return inverse(Relation.Kinds.HAS_ONE, "Relation.hasOne()", referenceTable,
        targetForeignKeyColumn, options)
end

--- @param referenceTable string
--- @param targetForeignKeyColumn string
--- @param options table?
--- @return RelationDefinition
function Relation.hasMany(referenceTable, targetForeignKeyColumn, options)
    return inverse(Relation.Kinds.HAS_MANY, "Relation.hasMany()", referenceTable,
        targetForeignKeyColumn, options)
end

function Relation.isInstance(obj)
    return type(obj) == "table" and getmetatable(obj) == RelationDefinition
end

return Relation
