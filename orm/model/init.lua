local Field = require("orm.model.field")

local EntityProxy = require("orm.query.entity-proxy")
local FieldProxy = require("orm.query.field-proxy")
local OrderFieldProxy = require("orm.query.order-field-proxy")

--- @class ModelClass
--- @field tableName string
--- @field fields Field[]
--- @field primaryKey string?
--- @field new fun(data: table, applyDefaults: boolean?): ModelClass
--- @field asProxy fun(): EntityProxy
--- @field asOrderProxy fun(): OrderFieldProxy

--- @param tableName string
--- @param fieldSchema FieldDefinition[]
return function(tableName, fieldSchema)
    local ModelClass = {
        tableName = tableName,
        fields = {} --[[ @as Field[] ]],
        fieldsByName = {},
        primaryKey = nil,
    }

    local fieldProxies, orderProxies = {}, {}

    for _, definition in ipairs(fieldSchema) do
        local field = Field.new(definition)

        table.insert(ModelClass.fields, field)
        ModelClass.fieldsByName[field.name] = field

        fieldProxies[field.name] = FieldProxy.new(tableName, field.name)
        orderProxies[field.name] = OrderFieldProxy.new(tableName, field.name)

        if field.primaryKey and ModelClass.primaryKey == nil then
            ModelClass.primaryKey = field.name
        elseif field.primaryKey then
            error("A model can only have one primary key field")
        end
    end

    local entityProxy = EntityProxy.new(ModelClass, fieldProxies)

    function ModelClass.new(data, applyDefaults)
        local self = {
            _attributes = {},
            _entry = nil,
        }

        data = data or {}
        applyDefaults = applyDefaults ~= false

        for _, field in ipairs(ModelClass.fields) do
            if data[field.name] ~= nil then
                self._attributes[field.name] = data[field.name]
            elseif applyDefaults and field.default ~= nil then
                if type(field.default) == "function" then
                    self._attributes[field.name] = field.default()
                else
                    self._attributes[field.name] = field.default
                end
            end
        end

        return setmetatable(self, ModelClass)
    end

    function ModelClass.__index(self, key)
        if ModelClass.fieldsByName[key] then
            return rawget(self, "_attributes")[key]
        end

        if ModelClass[key] then
            return ModelClass[key]
        end

        error("Attribute '" .. key .. "' does not exist")
    end

    function ModelClass.__newindex(self, key, value)
        if not ModelClass.fieldsByName[key] then
            error(string.format("Couldn't set %s to %s on Entity; field does not exist", key, value))
        end

        local attributes = rawget(self, "_attributes")
        local previousValue = attributes[key]
        if previousValue == value then
            return
        end

        attributes[key] = value

        local entry = rawget(self, "_entry")
        if entry then
            entry:recordChange(key, previousValue, value)
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
