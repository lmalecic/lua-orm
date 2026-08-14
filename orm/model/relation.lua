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

--- @alias RelationDefinition BelongsToDefinition
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

function Relation.hasOne(tbl, column)

end

function Relation.hasMany(tbl, column)

end

function Relation.isInstance(obj)
    return type(obj) == "table" and getmetatable(obj) == RelationDefinition
end

return Relation
