local Field = require("orm.model.field")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

--- @class ModelRelation
--- @field name string
--- @field kind RelationKind
--- @field referenceTable string
--- @field referenceColumn string
--- @field foreignKeyColumn string
--- @field constraints Constraint[]
--- @field required boolean
--- @field referenceModel ModelClass?
--- @field referenceField Field?
--- @field foreignKeyField Field?
local ModelRelation = {}
ModelRelation.__index = ModelRelation

--- @param definition table
--- @return ModelRelation
function ModelRelation.new(definition)
    assert(type(definition) == "table", "Relation definition must be a table")

    local name = definition[1]
    local relationDefinition = definition[2]

    assert(type(name) == "string" and name ~= "",
        "First element of relation definition must be a non-empty string indicating the property name")
    assert(Relation.isInstance(relationDefinition),
        "Second element of relation definition must be a RelationDefinition object")
    assert(relationDefinition.kind == Relation.Kinds.BELONGS_TO,
        "Only BELONGS_TO relations are currently supported")

    local constraints = {}
    local required = false

    for i = 3, #definition do
        local constraint = definition[i]
        assert(Constraint.isInstance(constraint),
            "Invalid constraint definition at index " .. i .. "; relation constraints must be Constraint objects")
        assert(constraint.kind ~= Constraint.Kinds.FOREIGN_KEY,
            "Relation definitions create their foreign key automatically and cannot use Constraint.ForeignKey()")

        table.insert(constraints, constraint)
        required = required or constraint.kind == Constraint.Kinds.NOT_NULL
    end

    local foreignKeyColumn = relationDefinition.foreignKeyColumn
        or name .. "_" .. relationDefinition.referenceColumn

    assert(foreignKeyColumn ~= name,
        "Relation property and foreign-key column cannot have the same name")

    return setmetatable({
        name = name,
        kind = relationDefinition.kind,
        referenceTable = relationDefinition.referenceTable,
        referenceColumn = relationDefinition.referenceColumn,
        foreignKeyColumn = foreignKeyColumn,
        constraints = constraints,
        required = required,
        referenceModel = nil,
        referenceField = nil,
        foreignKeyField = nil,
    }, ModelRelation)
end

--- Resolves the referenced model field and creates the physical foreign-key field.
--- Calling this again with the same schema returns the existing field.
--- @param ownerModel ModelClass
--- @param modelClasses table<string, ModelClass>
--- @return Field
function ModelRelation:resolve(ownerModel, modelClasses)
    local referenceModel = assert(modelClasses[self.referenceTable],
        string.format("Relation '%s.%s' references unknown model '%s'",
            ownerModel.tableName, self.name, self.referenceTable))
    local referenceField = assert(referenceModel.fieldsByName[self.referenceColumn],
        string.format("Relation '%s.%s' references unknown field '%s.%s'",
            ownerModel.tableName, self.name, self.referenceTable, self.referenceColumn))

    assert(referenceField.type,
        string.format("Cannot infer type for relation '%s.%s' from unresolved field '%s.%s'",
            ownerModel.tableName, self.name, self.referenceTable, self.referenceColumn))

    if self.foreignKeyField then
        assert(self.referenceModel == referenceModel and self.referenceField == referenceField,
            string.format("Relation '%s.%s' was already resolved against a different schema",
                ownerModel.tableName, self.name))
        return self.foreignKeyField
    end

    local generatedDefinition = { self.foreignKeyColumn, referenceField.type }
    for _, constraint in ipairs(self.constraints) do
        table.insert(generatedDefinition, constraint)
    end
    table.insert(generatedDefinition,
        Constraint.ForeignKey(self.referenceTable, self.referenceColumn))

    self.referenceModel = referenceModel
    self.referenceField = referenceField
    self.foreignKeyField = Field.new(generatedDefinition)

    return self.foreignKeyField
end

return ModelRelation
