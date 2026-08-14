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

--- @type PrimaryKeyConstraint
Constraint.PrimaryKey = { kind = Constraint.Kinds.PRIMARY_KEY }
--- @type NotNullConstraint
Constraint.NotNull = { kind = Constraint.Kinds.NOT_NULL }
--- @type UniqueConstraint
Constraint.Unique = { kind = Constraint.Kinds.UNIQUE }

--- @param identityMode IdentityMode?
--- @return AutoIncrementConstraint
function Constraint.AutoIncrement(identityMode)
    return { kind = Constraint.Kinds.AUTO_INCREMENT, identityMode = identityMode or Constraint.IdentityMode.ALWAYS }
end

--- @param value any
--- @return DefaultConstraint
function Constraint.Default(value)
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
