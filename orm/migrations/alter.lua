local Field = require("orm.model.field")

--- @class AddColumnAlteration
--- @field kind "ADD_COLUMN"
--- @field field Field

--- @class DropColumnAlteration
--- @field kind "DROP_COLUMN"
--- @field name string

--- @class ConstraintAlteration
--- @field kind "ADD_CONSTRAINT" | "DROP_CONSTRAINT"
--- @field type "PRIMARY_KEY" | "UNIQUE"
--- @field name string
--- @field columnName string

--- @alias Alteration AddColumnAlteration | DropColumnAlteration | ConstraintAlteration

local Alter = {}

--- @enum AlterationKind
Alter.Kinds = {
    ADD_COLUMN = "ADD_COLUMN",
    DROP_COLUMN = "DROP_COLUMN",
    DROP_CONSTRAINT = "DROP_CONSTRAINT",
    ADD_CONSTRAINT = "ADD_CONSTRAINT",
}

Alter.ConstraintTypes = {
    PRIMARY_KEY = "PRIMARY_KEY",
    UNIQUE = "UNIQUE",
}

---@param definition FieldDefinition
---@return AddColumnAlteration
function Alter.addColumn(definition)
    return { kind = Alter.Kinds.ADD_COLUMN, field = Field.new(definition) }
end

---@param name string
---@return DropColumnAlteration
function Alter.dropColumn(name)
    return { kind = Alter.Kinds.DROP_COLUMN, name = name }
end

---@param name string
---@return ConstraintAlteration
function Alter.addPrimaryKeyConstraint(name, columnName)
    return { kind = Alter.Kinds.ADD_CONSTRAINT, type = Alter.ConstraintTypes.PRIMARY_KEY, name = name, columnName = columnName }
end

---@param name string
---@return ConstraintAlteration
function Alter.addUniqueKeyConstraint(name, columnName)
    return { kind = Alter.Kinds.ADD_CONSTRAINT, type = Alter.ConstraintTypes.UNIQUE, name = name, columnName = columnName }
end

---@param name string
---@return ConstraintAlteration
function Alter.dropConstraint(name)
    return { kind = Alter.Kinds.DROP_CONSTRAINT, name = name }
end

return Alter
