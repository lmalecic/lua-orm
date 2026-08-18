local ValueHelper = require("orm.helpers.value")

--- @class PrimaryKeyConstraint
--- @field kind "PRIMARY_KEY"

--- @class NotNullConstraint
--- @field kind "NOT_NULL"

--- @class UniqueConstraint
--- @field kind "UNIQUE"

--- @class AutoIncrementConstraint
--- @field kind "AUTO_INCREMENT"
--- @field identityMode IdentityMode?

--- @class DefaultConstraint
--- @field kind "DEFAULT"
--- @field value any

--- @class ForeignKeyConstraint
--- @field kind "FOREIGN_KEY"
--- @field referenceTable string
--- @field referenceColumn string


--- @alias Constraint
--- | PrimaryKeyConstraint
--- | NotNullConstraint
--- | UniqueConstraint
--- | AutoIncrementConstraint
--- | DefaultConstraint
--- | ForeignKeyConstraint

local Constraint = {}

--- @enum ConstraintKind
Constraint.Kinds = {
    PRIMARY_KEY = "PRIMARY_KEY",
    AUTO_INCREMENT = "AUTO_INCREMENT",
    NOT_NULL = "NOT_NULL",
    UNIQUE = "UNIQUE",
    DEFAULT = "DEFAULT",
    FOREIGN_KEY = "FOREIGN_KEY"
}

--- @enum IdentityMode
Constraint.IdentityMode = {
    ALWAYS = "ALWAYS",
    BY_DEFAULT = "BY_DEFAULT"
}

local DEFAULT_IDENTITY_MODE = Constraint.IdentityMode.ALWAYS

--- @type PrimaryKeyConstraint
Constraint.PrimaryKey = { kind = Constraint.Kinds.PRIMARY_KEY }
--- @type NotNullConstraint
Constraint.NotNull = { kind = Constraint.Kinds.NOT_NULL }
--- @type UniqueConstraint
Constraint.Unique = { kind = Constraint.Kinds.UNIQUE }

function Constraint.identityModeAsCode(identityMode)
    assert(Constraint.IdentityMode[identityMode] ~= nil, "Invalid identity mode: " .. tostring(identityMode))
    return ("Constraint.IdentityMode.%s"):format(identityMode)
end

--- @param constraint Constraint
function Constraint.asCode(constraint)
    if constraint.kind == Constraint.Kinds.PRIMARY_KEY then
        return "Constraint.PrimaryKey"
    elseif constraint.kind == Constraint.Kinds.NOT_NULL then
        return "Constraint.NotNull"
    elseif constraint.kind == Constraint.Kinds.UNIQUE then
        return "Constraint.Unique"
    elseif constraint.kind == Constraint.Kinds.DEFAULT then
        return ("Constraint.Default(%s)"):format(ValueHelper.valueToCode(constraint.value))
    elseif constraint.kind == Constraint.Kinds.AUTO_INCREMENT then
        return ("Constraint.AutoIncrement(%s)"):format(Constraint.identityModeAsCode(constraint.identityMode))
    elseif constraint.kind == Constraint.Kinds.FOREIGN_KEY then
        return ("Constraint.ForeignKey(%q, %q)"):format(constraint.referenceTable, constraint.referenceColumn)
    end
    error("Unsupported constraint of kind " .. constraint.kind .. " in Constraint.asCode()")
end

--- @param identityMode IdentityMode?
--- @return AutoIncrementConstraint
function Constraint.AutoIncrement(identityMode)
    return { kind = Constraint.Kinds.AUTO_INCREMENT, identityMode = identityMode or DEFAULT_IDENTITY_MODE }
end

--- @param value any
--- @return DefaultConstraint
function Constraint.Default(value)
    assert(value ~= nil, "Default constraint value cannot be nil; it is not necessary to specify a nil default value for a column as it defaults to NULL if its nullable. If it is not nullable, you must specify a non-nil value instead")
    return { kind = Constraint.Kinds.DEFAULT, value = value }
end

--- @param referenceTable string
--- @param referenceColumn string
--- @return ForeignKeyConstraint
function Constraint.ForeignKey(referenceTable, referenceColumn)
    return { kind = Constraint.Kinds.FOREIGN_KEY, referenceTable = referenceTable, referenceColumn = referenceColumn }
end

function Constraint.isInstance(obj)
    return type(obj) == "table" and Constraint.Kinds[obj.kind]
end

return Constraint
