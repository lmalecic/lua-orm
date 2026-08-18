local Field = require("orm.model.field")
local ValueHelper = require("orm.helpers.value")
local Constraint = require("orm.model.constraint")

--- @class AddColumnAlteration
--- @field kind "ADD_COLUMN"
--- @field field Field

--- @class DropColumnAlteration
--- @field kind "DROP_COLUMN"
--- @field column string

--- @class ConstraintAlteration
--- @field kind "ADD_CONSTRAINT" | "DROP_CONSTRAINT"
--- @field type "PRIMARY_KEY" | "UNIQUE"
--- @field name string
--- @field columnName string

--- @class ForeignKeyConstraintAlteration
--- @field kind "ADD_CONSTRAINT"
--- @field type "FOREIGN_KEY"
--- @field name string
--- @field columnName string
--- @field referenceTable string
--- @field referenceColumn string

--- @class ColumnRenameAlteration
--- @field kind "ALTER_COLUMN"
--- @field operation "RENAME"
--- @field column string
--- @field newName string

--- @class ColumnTypeAlteration
--- @field kind "ALTER_COLUMN"
--- @field operation "SET_TYPE"
--- @field column string
--- @field type Type

--- @class ColumnNotNullAlteration
--- @field kind "ALTER_COLUMN"
--- @field operation "SET_NOT_NULL"
--- @field column string

--- @class ColumnDropNotNullAlteration
--- @field kind "ALTER_COLUMN"
--- @field operation "DROP_NOT_NULL"
--- @field column string

--- @class ColumnSetDefaultAlteration
--- @field kind "ALTER_COLUMN"
--- @field operation "SET_DEFAULT"
--- @field column string
--- @field default any

--- @class ColumnDropDefaultAlteration
--- @field kind "ALTER_COLUMN"
--- @field operation "DROP_DEFAULT"
--- @field column string

--- @class ColumnAddAutoIncrementAlteration
--- @field kind "ALTER_COLUMN"
--- @field operation "ADD_AUTO_INCREMENT"
--- @field column string
--- @field identityMode IdentityMode?
--- @field startWith number?

--- @class ColumnSetIdentityAlteration
--- @field kind "ALTER_COLUMN"
--- @field operation "SET_IDENTITY"
--- @field column string
--- @field identityMode IdentityMode?

--- @class ColumnDropIdentityAlteration
--- @field kind "ALTER_COLUMN"
--- @field operation "DROP_IDENTITY"
--- @field column string

--- @class ColumnAlteration
--- | ColumnRenameAlteration
--- | ColumnTypeAlteration
--- | ColumnNotNullAlteration
--- | ColumnDropNotNullAlteration
--- | ColumnDefaultAlteration
--- | ColumnDropDefaultAlteration
--- | ColumnAddAutoIncrementAlteration
--- | ColumnSetIdentityAlteration
--- | ColumnDropIdentityAlteration

--- @alias Alteration
--- | AddColumnAlteration
--- | DropColumnAlteration
--- | ConstraintAlteration
--- | ForeignKeyConstraintAlteration
--- | ColumnAlteration

local Alter = {}

--- @enum AlterationKind
Alter.Kinds = {
    ADD_COLUMN = "ADD_COLUMN",
    DROP_COLUMN = "DROP_COLUMN",
    ALTER_COLUMN = "ALTER_COLUMN",
    ADD_CONSTRAINT = "ADD_CONSTRAINT",
    DROP_CONSTRAINT = "DROP_CONSTRAINT",
}

--- @enum ColumnAlterationOperation
Alter.ColumnOperation = {
    RENAME = "RENAME",
    SET_TYPE = "SET_TYPE",
    SET_NOT_NULL = "SET_NOT_NULL",
    DROP_NOT_NULL = "DROP_NOT_NULL",
    SET_DEFAULT = "SET_DEFAULT",
    DROP_DEFAULT = "DROP_DEFAULT",
    ADD_AUTO_INCREMENT = "ADD_AUTO_INCREMENT",
    SET_IDENTITY = "SET_IDENTITY",
    DROP_IDENTITY = "DROP_IDENTITY",
}

Alter.ConstraintTypes = {
    PRIMARY_KEY = "PRIMARY_KEY",
    UNIQUE = "UNIQUE",
    FOREIGN_KEY = "FOREIGN_KEY",
}

local AlterMetatable = {}
AlterMetatable.__index = AlterMetatable

---@param self Alteration
function AlterMetatable:toCode()
    if self.kind == Alter.Kinds.ADD_COLUMN then
        return ('Alter.addColumn(%s)'):format(self.field:definitionToCode())
    elseif self.kind == Alter.Kinds.DROP_COLUMN then
        return ('Alter.dropColumn(%q)'):format(self.column)
    elseif self.kind == Alter.Kinds.ALTER_COLUMN and self.operation == Alter.ColumnOperation.RENAME then
        return ('Alter.renameColumn("%s", "%s")'):format(self.column, self.newName)
    elseif self.kind == Alter.Kinds.ALTER_COLUMN and self.operation == Alter.ColumnOperation.SET_TYPE then
        return ('Alter.setColumnType(%q, Types.%s)'):format(self.column, self.type:toGeneratorReferenceString())
    elseif self.kind == Alter.Kinds.ALTER_COLUMN and self.operation == Alter.ColumnOperation.SET_NOT_NULL then
        return ('Alter.setColumnNotNull("%s")'):format(self.column)
    elseif self.kind == Alter.Kinds.ALTER_COLUMN and self.operation == Alter.ColumnOperation.DROP_NOT_NULL then
        return ('Alter.dropColumnNotNull("%s")'):format(self.column)
    elseif self.kind == Alter.Kinds.ALTER_COLUMN and self.operation == Alter.ColumnOperation.SET_DEFAULT then
        return ('Alter.setColumnDefault(%q, %s)'):format(self.column, ValueHelper.valueToCode(self.default))
    elseif self.kind == Alter.Kinds.ALTER_COLUMN and self.operation == Alter.ColumnOperation.DROP_DEFAULT then
        return ('Alter.dropColumnDefault("%s")'):format(self.column)
    elseif self.kind == Alter.Kinds.ALTER_COLUMN and self.operation == Alter.ColumnOperation.ADD_AUTO_INCREMENT then
        return ('Alter.addColumnAutoIncrement(%q, %s, %s)'):format(
            self.column,
            ValueHelper.valueToCode(self.identityMode),
            ValueHelper.valueToCode(self.startWith) or "nil")
    elseif self.kind == Alter.Kinds.ALTER_COLUMN and self.operation == Alter.ColumnOperation.SET_IDENTITY then
        return ('Alter.setColumnIdentity(%q, %s)'):format(self.column, Constraint.identityModeAsCode(self.identityMode))
    elseif self.kind == Alter.Kinds.ALTER_COLUMN and self.operation == Alter.ColumnOperation.DROP_IDENTITY then
        return ('Alter.dropColumnIdentity("%s")'):format(self.column)
    elseif self.kind == Alter.Kinds.ADD_CONSTRAINT and self.type == Alter.ConstraintTypes.PRIMARY_KEY then
        return ('Alter.addPrimaryKeyConstraint(%q, %q)'):format(self.name, self.columnName)
    elseif self.kind == Alter.Kinds.ADD_CONSTRAINT and self.type == Alter.ConstraintTypes.UNIQUE then
        return ('Alter.addUniqueKeyConstraint(%q, %q)'):format(self.name, self.columnName)
    elseif self.kind == Alter.Kinds.ADD_CONSTRAINT and self.type == Alter.ConstraintTypes.FOREIGN_KEY then
        return ('Alter.addForeignKeyConstraint(%q, %q, %q, %q)'):format(
            self.name,
            self.columnName,
            self.referenceTable,
            self.referenceColumn)
    elseif self.kind == Alter.Kinds.DROP_CONSTRAINT then
        return ('Alter.dropConstraint(%q)'):format(self.name)
    end

    error("Unsupported alteration in Alteration:toCode()")
end

---@param definition FieldDefinition | Field
---@return AddColumnAlteration
function Alter.addColumn(definition)
    local field = definition.name and definition.type and definition or Field.new(definition)
    return setmetatable({ kind = Alter.Kinds.ADD_COLUMN, field = field }, AlterMetatable)
end

---@param column string
---@return DropColumnAlteration
function Alter.dropColumn(column)
    return setmetatable({ kind = Alter.Kinds.DROP_COLUMN, column = column }, AlterMetatable)
end

---@param column string
---@param newName string
---@return ColumnRenameAlteration
function Alter.renameColumn(column, newName)
    return setmetatable({ kind = Alter.Kinds.ALTER_COLUMN, operation = Alter.ColumnOperation.RENAME, column = column, newName = newName }, AlterMetatable)
end

---@param column string
---@param type Type
---@return ColumnTypeAlteration
function Alter.setColumnType(column, type)
    return setmetatable({ kind = Alter.Kinds.ALTER_COLUMN, operation = Alter.ColumnOperation.SET_TYPE, column = column, type = type }, AlterMetatable)
end

---@param column string
---@return ColumnNotNullAlteration
function Alter.setColumnNotNull(column)
    return setmetatable({ kind = Alter.Kinds.ALTER_COLUMN, operation = Alter.ColumnOperation.SET_NOT_NULL, column = column }, AlterMetatable)
end

---@param column string
---@return ColumnDropNotNullAlteration
function Alter.dropColumnNotNull(column)
    return setmetatable({ kind = Alter.Kinds.ALTER_COLUMN, operation = Alter.ColumnOperation.DROP_NOT_NULL, column = column }, AlterMetatable)
end

---@param column string
---@param value any
---@return ColumnSetDefaultAlteration
function Alter.setColumnDefault(column, value)
    assert(value ~= nil, "Default value must not be nil, if you wish to set it to nil, use dropColumnDefault() instead")
    return setmetatable({ kind = Alter.Kinds.ALTER_COLUMN, operation = Alter.ColumnOperation.SET_DEFAULT, column = column, default = value }, AlterMetatable)
end

---@param column string
---@return ColumnDropDefaultAlteration
function Alter.dropColumnDefault(column)
    return setmetatable({ kind = Alter.Kinds.ALTER_COLUMN, operation = Alter.ColumnOperation.DROP_DEFAULT, column = column }, AlterMetatable)
end

---@param column string
---@param identityMode IdentityMode?
---@param startWith number?
---@return ColumnAddAutoIncrementAlteration
function Alter.addColumnAutoIncrement(column, identityMode, startWith)
    -- For now startWith doesn't do anything
    return setmetatable({
        kind = Alter.Kinds.ALTER_COLUMN,
        operation = Alter.ColumnOperation.ADD_AUTO_INCREMENT,
        column = column,
        identityMode = identityMode or Constraint.IdentityMode.ALWAYS,
        startWith = startWith,
    }, AlterMetatable)
end

---@param column string
---@param identityMode IdentityMode?
---@return ColumnSetIdentityAlteration
function Alter.setColumnIdentity(column, identityMode)
    return setmetatable({
        kind = Alter.Kinds.ALTER_COLUMN,
        operation = Alter.ColumnOperation.SET_IDENTITY,
        column = column,
        identityMode = identityMode or Constraint.IdentityMode.ALWAYS,
    }, AlterMetatable)
end

--- @param column string
--- @return ColumnDropIdentityAlteration
function Alter.dropColumnIdentity(column)
    return setmetatable({ kind = Alter.Kinds.ALTER_COLUMN, operation = Alter.ColumnOperation.DROP_IDENTITY, column = column }, AlterMetatable)
end

---@param name string
---@param column string
---@return ConstraintAlteration
function Alter.addPrimaryKeyConstraint(name, column)
    return setmetatable({ kind = Alter.Kinds.ADD_CONSTRAINT, type = Alter.ConstraintTypes.PRIMARY_KEY, name = name, columnName = column }, AlterMetatable)
end

---@param name string
---@param column string
---@return ConstraintAlteration
function Alter.addUniqueKeyConstraint(name, column)
    return setmetatable({ kind = Alter.Kinds.ADD_CONSTRAINT, type = Alter.ConstraintTypes.UNIQUE, name = name, columnName = column }, AlterMetatable)
end

---@param name string
---@param column string
---@param referenceTable string
---@param referenceColumn string
---@return ConstraintAlteration
function Alter.addForeignKeyConstraint(name, column, referenceTable, referenceColumn)
    return setmetatable({ kind = Alter.Kinds.ADD_CONSTRAINT, type = Alter.ConstraintTypes.FOREIGN_KEY, name = name, columnName = column, referenceTable = referenceTable, referenceColumn = referenceColumn }, AlterMetatable)
end

---@param name string
---@return ConstraintAlteration
function Alter.dropConstraint(name)
    return setmetatable({ kind = Alter.Kinds.DROP_CONSTRAINT, name = name }, AlterMetatable)
end

return Alter
