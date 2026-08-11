local Field = require("orm.model.field")

local EntityProxy = require("orm.query.entity-proxy")
local FieldProxy = require("orm.query.field-proxy")
local OrderFieldProxy = require("orm.query.order-field-proxy")

--- @class ModelClass
--- @field tableName string
--- @field fields { [number]: Field }
--- @field primaryKey string
--- @field new fun(data: table): ModelClass
--- @field asProxy fun(): FieldProxy
--- @field asOrderProxy fun(): OrderFieldProxy

--- @param tableName string
--- @param fieldSchema FieldDefinition[]
return function(tableName, fieldSchema)
    local ModelClass = {}
    ModelClass.__index = ModelClass
    ModelClass.tableName = tableName
    ModelClass.fields = {}
    ModelClass.primaryKey = nil

    local fieldProxies, orderProxies = {}, {}

    for _, definition in ipairs(fieldSchema) do
        local field = Field.new(definition)

        table.insert(ModelClass.fields, field)

        fieldProxies[field.name] = FieldProxy.new(tableName, field.name)
        orderProxies[field.name] = OrderFieldProxy.new(tableName, field.name)

        if field.primaryKey and ModelClass.primaryKey == nil then
            ModelClass.primaryKey = field.name
        elseif field.primaryKey then
            error("A model can only have one primary key field")
        end
    end

    local entityProxy = EntityProxy.new(ModelClass, fieldProxies)

    function ModelClass.new(data)
        local self = setmetatable({}, ModelClass)
        self._attributes = {}
        self._isPersisted = false

        data = data or {}

        for name, field in pairs(ModelClass.fields) do
            if data[name] ~= nil then
                self._attributes[name] = data[name]
            elseif field.defaultValue ~= nil then
                if type(field.defaultValue) == "table" then
                    self._attributes[name] = tostring(field.defaultValue) -- TODO: Check if CurrentTimestamp would
                elseif type(field.defaultValue) == "function" then
                    self._attributes[name] = field.defaultValue()
                else
                    self._attributes[name] = field.defaultValue
                end
            end
        end
    end

    function ModelClass.asProxy()
        return entityProxy
    end

    function ModelClass.asOrderProxy()
        return orderProxies
    end

    return ModelClass
end
