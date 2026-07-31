local Context = require("orm.core.context")

local orm = {
    new = Context.new,
    DbContext = Context,
    Connection = require("orm.core.connection"),
    UnitOfWork = require("orm.core.unit_of_work"),
    DataSet = require("orm.runtime.dataset"),
    EntityState = require("orm.runtime.entity_state"),
    Model = require("orm.metadata.model"),
    Field = require("orm.metadata.field"),
    Types = require("orm.metadata.types"),
    Query = require("orm.query"),
    Migrations = require("orm.migrations.schema_sync"),
}

return setmetatable(orm, {
    __call = function(self, ...)
        return self.new(...)
    end,
})
