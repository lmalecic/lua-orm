local FieldProxy = require("orm.query.field-proxy")
-- local Expressions = require("orm.model.expressions")

local function isSqlExpression(value)

end

--- @class ModelClass
--- @field tableName string
--- @field fields { [number]: Field }
--- @field primaryKey string
--- @field new fun(data: table): ModelClass

--- @param tableName string
--- @param fields { [number]: Field }
return function(tableName, fields)
    local ModelClass = {}
    ModelClass.__index = ModelClass
    ModelClass.tableName = tableName
    ModelClass.fields = fields
    ModelClass.primaryKey = nil

    local fieldProxies = {}

    for _, field in ipairs(fields) do
        ModelClass.fields[field.name] = field
        fieldProxies[field.name] = FieldProxy.new(tableName, field.name)

        if field.isPrimaryKey then
            ModelClass.primaryKey = field.name
        end
    end

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
    	return fieldProxies
    end

    return ModelClass
end
