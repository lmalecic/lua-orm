local Type = require("orm.model.types.type")
local Constraint = require("orm.model.constraint")

--- @class ForeignKey
--- @field referenceTable string
--- @field referenceColumn string

--- @class Field
--- @field name string
--- @field type Type
--- @field nullable boolean
--- @field unique boolean
--- @field default any?
--- @field primaryKey boolean
--- @field autoIncrement boolean
--- @field identityMode IdentityMode?
--- @field foreignKey ForeignKey?
local Field = {}
Field.__index = Field

--- @alias FieldDefinition [string | Type | Constraint]

--- @param definition FieldDefinition
--- @return Field
function Field.new(definition)
    assert(type(definition) == "table", "Field definition must be a table")
    assert(type(definition[1]) == "string", "First element of field definition must be a string indicating the column name")
    assert(Type.isInstance(definition[2]), "Second element of field definition must be a subclass of Type indicating the field type")

    local fieldName = definition[1] --[[@as string]]
    local fieldType = definition[2] --[[@as Type]]

    local self = setmetatable({
        name = fieldName,
        type = fieldType,
        nullable = true,
        unique = false,
        default = nil,
        primaryKey = false,
        foreignKey = nil,
        autoIncrement = false,
        identityMode = nil,
	}, Field)

    for i = 3, #definition do
        local constraint = definition[i]
        assert(Constraint.isInstance(constraint), "Invalid constraint definition at index " .. i .. "; all objects starting from index 3 in the field defintion must be Constraint objects")

        if constraint.kind == Constraint.Kinds.PRIMARY_KEY then
            self.primaryKey = true
        elseif constraint.kind == Constraint.Kinds.AUTO_INCREMENT then
            assert(self.default == nil, "Auto-increment fields cannot have a default value")
            assert(self.foreignKey == nil, "Auto-increment fields cannot have a foreign key constraint, idk why you'd ever want that, this is an anti-pattern.")
            self.autoIncrement = true
            self.identityMode = constraint.identityMode
        elseif constraint.kind == Constraint.Kinds.NOT_NULL then
            self.nullable = false
        elseif constraint.kind == Constraint.Kinds.UNIQUE then
            self.unique = true
        elseif constraint.kind == Constraint.Kinds.DEFAULT then
            assert(self.autoIncrement == false, "Default value is not supported for auto-increment fields")
            self.default = constraint.value
        elseif constraint.kind == Constraint.Kinds.FOREIGN_KEY then
            assert(self.autoIncrement == false, "Foreign key fields cannot be auto-increment fields")
            self.foreignKey = {
                referenceTable = constraint.referenceTable,
                referenceColumn = constraint.referenceColumn,
            }
        end
    end

	return self
end

return Field
