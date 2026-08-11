local Type = require("orm.model.types.type")
local Constraint = require("orm.model.constraint")

--- @class Field
--- @field name string
--- @field type Type
--- @field nullable boolean
--- @field unique boolean
--- @field default any?
--- @field primaryKey boolean
--- @field autoIncrement boolean
--- @field identityMode IdentityMode?
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
        autoIncrement = false,
        identityMode = nil,
	}, Field)

    for i = 3, #definition do
        local constraint = definition[i]
        assert(type(constraint) == "table" and Constraint.Kinds[constraint.kind], "Invalid constraint definition at index " .. i)

        if constraint.kind == Constraint.Kinds.PRIMARY_KEY then
            self.primaryKey = true
        elseif constraint.kind == Constraint.Kinds.AUTO_INCREMENT then
            assert(self.default == nil, "Auto-increment fields cannot have a default value")
            self.autoIncrement = true
            self.identityMode = constraint.identityMode
        elseif constraint.kind == Constraint.Kinds.NOT_NULL then
            self.nullable = false
        elseif constraint.kind == Constraint.Kinds.UNIQUE then
            self.unique = true
        elseif constraint.kind == Constraint.Kinds.DEFAULT then
            assert(self.autoIncrement == false, "Default value is not supported for auto-increment fields")
            self.default = constraint.value
        end
    end

	return self
end

return Field
