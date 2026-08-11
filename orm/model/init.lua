local Field = require("orm.model.field")

local EntityProxy = require("orm.query.entity-proxy")
local FieldProxy = require("orm.query.field-proxy")
local OrderFieldProxy = require("orm.query.order-field-proxy")

--- @class ModelClass
--- @field tableName string
--- @field fields Field[]
--- @field primaryKey string?
--- @field new fun(data: table): ModelClass
--- @field asProxy fun(): EntityProxy
--- @field asOrderProxy fun(): OrderFieldProxy

--- @param tableName string
--- @param fieldSchema FieldDefinition[]
return function(tableName, fieldSchema)
    local ModelClass = {}
    ModelClass.tableName = tableName
    ModelClass.fields = {} --[[ @as Field[] ]]
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
        local self = {}
        self._attributes = {}
        self._isPersisted = false

        data = data or {}

        for _, field in ipairs(ModelClass.fields) do
            if data[field.name] ~= nil then
                self._attributes[field.name] = data[field.name]
            elseif field.default ~= nil then
                if type(field.default) == "table" then
                    self._attributes[field.name] = tostring(field.default) -- TODO: Check if CurrentTimestamp would
                elseif type(field.default) == "function" then
                    self._attributes[field.name] = field.default()
                else
                    self._attributes[field.name] = field.default
                end
            end
        end

        return setmetatable(self, ModelClass)
    end

    function ModelClass.__index(self, key)
        if self._attributes[key] then
            return self._attributes[key]
        end

        if ModelClass[key] then
            return ModelClass[key]
        end

        error("Attribute '" .. key .. "' does not exist")
    end

    function ModelClass.__newindex(_, key, value)
        error(string.format("Couldn't set %s to %s; Entities are immutable", key, value))
    end

    function ModelClass.asProxy()
        return entityProxy
    end

    function ModelClass.asOrderProxy()
        return orderProxies
    end

    return ModelClass
end
