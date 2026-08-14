local Field = require("orm.model.field")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local INVERSE_UNRESOLVED = {}
local resolutionKind = nil

--- @class ModelRelation
--- @field name string
--- @field kind RelationKind
--- @field referenceTable string
--- @field sourceColumn string?
--- @field targetColumn string
--- @field referenceColumn string
--- @field foreignKeyColumn string
--- @field constraints Constraint[]
--- @field required boolean
--- @field sourceModel ModelClass?
--- @field targetModel ModelClass?
--- @field sourceField Field?
--- @field targetField Field?
--- @field referenceModel ModelClass?
--- @field referenceField Field?
--- @field foreignKeyField Field?
local ModelRelation = {}
ModelRelation.__index = ModelRelation

--- Limits calls made through ModelClass.resolveRelations() to one relation kind.
--- Passing nil restores normal resolution.
--- @param kind RelationKind?
function ModelRelation.setResolutionKind(kind)
    assert(kind == nil or Relation.Kinds[kind], "Invalid relation resolution kind " .. tostring(kind))
    resolutionKind = kind
end

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

    local inverse = relationDefinition.kind ~= Relation.Kinds.BELONGS_TO
    assert(not inverse or #definition == 2,
        string.format("Inverse relation '%s' cannot define constraints because it does not generate a local field", name))

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

    local sourceColumn
    local targetColumn
    local foreignKeyField

    if inverse then
        sourceColumn = relationDefinition.localColumn
        targetColumn = relationDefinition.targetForeignKeyColumn
        -- ModelClass uses this value while registering relations. The marker ensures
        -- its resolver does not try to add a physical field for an inverse relation.
        foreignKeyField = INVERSE_UNRESOLVED
    else
        sourceColumn = relationDefinition.foreignKeyColumn
            or name .. "_" .. relationDefinition.referenceColumn
        targetColumn = relationDefinition.referenceColumn
    end

    local registrationColumn = inverse and ("\0inverse:" .. name) or sourceColumn
    assert(registrationColumn ~= name,
        "Relation property and foreign-key column cannot have the same name")

    return setmetatable({
        name = name,
        kind = relationDefinition.kind,
        referenceTable = relationDefinition.referenceTable,
        sourceColumn = sourceColumn,
        targetColumn = targetColumn,
        referenceColumn = targetColumn,
        foreignKeyColumn = registrationColumn,
        constraints = constraints,
        required = required,
        sourceModel = nil,
        targetModel = nil,
        sourceField = nil,
        targetField = nil,
        referenceModel = nil,
        referenceField = nil,
        foreignKeyField = foreignKeyField,
    }, ModelRelation)
end

local function assertCompatibleTypes(ownerModel, relation, sourceField, targetField)
    local sourceType = sourceField.type:toSql()
    local targetType = targetField.type:toSql()
    assert(sourceType == targetType,
        string.format("Relation '%s.%s' joins incompatible fields '%s.%s' (%s) and '%s.%s' (%s)",
            ownerModel.tableName, relation.name,
            ownerModel.tableName, sourceField.name, sourceType,
            relation.referenceTable, targetField.name, targetType))
end

--- Resolves join metadata and, for BELONGS_TO, creates the physical foreign-key field.
--- @param ownerModel ModelClass
--- @param modelClasses table<string, ModelClass>
--- @return Field
function ModelRelation:resolve(ownerModel, modelClasses)
    if resolutionKind and self.kind ~= resolutionKind then
        return self.foreignKeyField
    end

    local targetModel = assert(modelClasses[self.referenceTable],
        string.format("Relation '%s.%s' references unknown model '%s'",
            ownerModel.tableName, self.name, self.referenceTable))

    if self.kind == Relation.Kinds.BELONGS_TO then
        local targetField = assert(targetModel.fieldsByName[self.targetColumn],
            string.format("Relation '%s.%s' references unknown field '%s.%s'",
                ownerModel.tableName, self.name, self.referenceTable, self.targetColumn))

        assert(targetField.type,
            string.format("Cannot infer type for relation '%s.%s' from unresolved field '%s.%s'",
                ownerModel.tableName, self.name, self.referenceTable, self.targetColumn))

        if self.sourceField then
            assert(self.sourceModel == ownerModel and self.targetModel == targetModel
                    and self.targetField == targetField,
                string.format("Relation '%s.%s' was already resolved against a different schema",
                    ownerModel.tableName, self.name))
            return self.sourceField
        end

        local generatedDefinition = { self.sourceColumn, targetField.type }
        for _, constraint in ipairs(self.constraints) do
            table.insert(generatedDefinition, constraint)
        end
        table.insert(generatedDefinition,
            Constraint.ForeignKey(self.referenceTable, self.targetColumn))

        local sourceField = Field.new(generatedDefinition)
        self.sourceModel = ownerModel
        self.targetModel = targetModel
        self.sourceField = sourceField
        self.targetField = targetField
        self.referenceModel = targetModel
        self.referenceField = targetField
        self.foreignKeyField = sourceField
        self.foreignKeyColumn = self.sourceColumn

        return sourceField
    end

    if self.kind == Relation.Kinds.HAS_MANY then
        assert(ownerModel.primaryKey,
            string.format("HAS_MANY relation '%s.%s' requires owner model '%s' to have a primary key for query deduplication",
                ownerModel.tableName, self.name, ownerModel.tableName))
    end

    local sourceColumn = self.sourceColumn or assert(ownerModel.primaryKey,
        string.format("Inverse relation '%s.%s' requires model '%s' to have a primary key or options.localColumn",
            ownerModel.tableName, self.name, ownerModel.tableName))
    local sourceField = assert(ownerModel.fieldsByName[sourceColumn],
        string.format("Relation '%s.%s' uses unknown local field '%s.%s'",
            ownerModel.tableName, self.name, ownerModel.tableName, sourceColumn))
    local targetField = assert(targetModel.fieldsByName[self.targetColumn],
        string.format("Relation '%s.%s' references unknown target foreign-key field '%s.%s'",
            ownerModel.tableName, self.name, self.referenceTable, self.targetColumn))
    local foreignKey = targetField.foreignKey

    assert(foreignKey,
        string.format("Inverse relation '%s.%s' target field '%s.%s' is not a foreign key",
            ownerModel.tableName, self.name, self.referenceTable, self.targetColumn))
    assert(foreignKey.referenceTable == ownerModel.tableName
            and foreignKey.referenceColumn == sourceColumn,
        string.format("Inverse relation '%s.%s' target field '%s.%s' must reference '%s.%s'",
            ownerModel.tableName, self.name, self.referenceTable, self.targetColumn,
            ownerModel.tableName, sourceColumn))

    assertCompatibleTypes(ownerModel, self, sourceField, targetField)

    if self.kind == Relation.Kinds.HAS_ONE then
        assert(targetField.unique or targetField.primaryKey,
            string.format("HAS_ONE relation '%s.%s' requires target foreign-key field '%s.%s' to be unique or a primary key",
                ownerModel.tableName, self.name, self.referenceTable, self.targetColumn))
    else
        assert(targetModel.primaryKey,
            string.format("HAS_MANY relation '%s.%s' requires target model '%s' to have a primary key for query deduplication",
                ownerModel.tableName, self.name, self.referenceTable))
    end

    if self.sourceField and self.foreignKeyField ~= INVERSE_UNRESOLVED then
        assert(self.sourceModel == ownerModel and self.targetModel == targetModel
                and self.sourceField == sourceField and self.targetField == targetField,
            string.format("Relation '%s.%s' was already resolved against a different schema",
                ownerModel.tableName, self.name))
        return self.sourceField
    end

    self.sourceColumn = sourceColumn
    self.sourceModel = ownerModel
    self.targetModel = targetModel
    self.sourceField = sourceField
    self.targetField = targetField
    self.referenceModel = targetModel
    self.referenceField = targetField
    -- Legacy aliases describe the owner-to-target join direction. No field is added.
    self.foreignKeyColumn = sourceColumn
    self.referenceColumn = self.targetColumn
    self.foreignKeyField = sourceField

    return sourceField
end

return ModelRelation
