local Field = require("orm.model.field")
local Relation = require("orm.model.relation")
local ModelRelation = require("orm.model.model-relation")

local EntityProxy = require("orm.query.proxy.entity")
local FieldProxy = require("orm.query.proxy.field")
local OrderFieldProxy = require("orm.query.proxy.order-field")
local RelationFieldProxy = require("orm.query.proxy.relation-field")
local EntityRelationProxy = require("orm.query.proxy.entity-relation")


--- @class ModelClass
--- @field tableName string
--- @field fields Field[]
--- @field fieldsByName table<string, Field>
--- @field relations table<string, ModelRelation>
--- @field primaryKey string?
--- @field new fun(data: table, applyDefaults: boolean?): ModelClass
--- @field resolveRelations fun(modelClasses: table<string, ModelClass>)
--- @field _setLoadedRelation fun(entity: ModelClass, relationName: string, relatedEntity: ModelClass?)
--- @field asProxy fun(): EntityProxy
--- @field asOrderProxy fun(): OrderFieldProxy
--- @field asRelationProxy fun(): EntityRelationProxy

--- @param tableName string
--- @param fieldSchema table[]
return function(tableName, fieldSchema)
    local ModelClass = {
        tableName = tableName,
        fields = {} --[[ @as Field[] ]],
        fieldsByName = {},
        relations = {} --[[ @as table<string, ModelRelation> ]],
        primaryKey = nil,
    }

    local fieldProxies, orderProxies, relationFieldProxies = {}, {}, {}
    local relationsByForeignKey = {}

    --- @param field Field
    local function addField(field)
        assert(not ModelClass.fieldsByName[field.name],
            string.format("Field '%s' is defined more than once on model '%s'", field.name, tableName))
        assert(not ModelClass.relations[field.name],
            string.format("Field '%s' conflicts with a relation of the same name on model '%s'", field.name, tableName))

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

    --- @param definition table
    local function addRelation(definition)
        local relation = ModelRelation.new(definition)

        assert(not ModelClass.fieldsByName[relation.name],
            string.format("Relation '%s' conflicts with a field of the same name on model '%s'",
                relation.name, tableName))
        assert(not ModelClass.relations[relation.name],
            string.format("Relation '%s' is defined more than once on model '%s'",
                relation.name, tableName))
        assert(not ModelClass.fieldsByName[relation.foreignKeyColumn],
            string.format("Generated foreign-key field '%s' already exists on model '%s'",
                relation.foreignKeyColumn, tableName))
        assert(not relationsByForeignKey[relation.foreignKeyColumn],
            string.format("Foreign-key field '%s' is used by more than one relation on model '%s'",
                relation.foreignKeyColumn, tableName))

        ModelClass.relations[relation.name] = relation
        relationsByForeignKey[relation.foreignKeyColumn] = relation
        relationFieldProxies[relation.name] = RelationFieldProxy.new(
            tableName,
            relation.name,
            relation.foreignKeyColumn,
            relation.referenceTable,
            relation.referenceColumn,
            relation.required
        )
    end

    for _, definition in ipairs(fieldSchema) do
        if Relation.isInstance(definition[2]) then
            addRelation(definition)
        else
            addField(Field.new(definition))
        end
    end

    local entityProxy = EntityProxy.new(ModelClass, fieldProxies)
    local relationProxy = EntityRelationProxy.new(ModelClass, relationFieldProxies)

    --- Resolves relation targets and creates their physical foreign-key fields.
    --- This runs after every model in the context schema is known.
    --- @param modelClasses table<string, ModelClass>
    function ModelClass.resolveRelations(modelClasses)
        for _, relation in pairs(ModelClass.relations) do
            local wasResolved = relation.foreignKeyField ~= nil
            local foreignKeyField = relation:resolve(ModelClass, modelClasses)

            if not wasResolved then
                addField(foreignKeyField)
            end
        end
    end

    function ModelClass.new(data, applyDefaults)
        local self = setmetatable({
            _attributes = {},
            _relations = {},
            _entry = nil,
        }, ModelClass)

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

        for _, relation in pairs(ModelClass.relations) do
            if data[relation.name] ~= nil then
                self[relation.name] = data[relation.name]
            end
        end

        return self
    end

    function ModelClass.__index(self, key)
        if ModelClass.fieldsByName[key] then
            return rawget(self, "_attributes")[key]
        end

        if ModelClass.relations[key] then
            return rawget(self, "_relations")[key]
        end

        if ModelClass[key] then
            return ModelClass[key]
        end

        error("Attribute '" .. key .. "' does not exist")
    end

    function ModelClass.__newindex(self, key, value)
        local field = ModelClass.fieldsByName[key]
        if field then
            local attributes = rawget(self, "_attributes")
            local previousValue = attributes[key]
            if previousValue == value then
                return
            end

            attributes[key] = value

            local relation = relationsByForeignKey[key]
            if relation then
                rawget(self, "_relations")[relation.name] = nil
            end

            local entry = rawget(self, "_entry")
            if entry then
                entry:recordChange(key, previousValue, value)
            end
            return
        end

        local relation = ModelClass.relations[key]
        if relation then
            assert(relation.foreignKeyField and relation.referenceModel,
                string.format("Relation '%s.%s' has not been resolved by a context", tableName, key))

            local referenceValue = nil
            if value ~= nil then
                assert(type(value) == "table" and getmetatable(value) == relation.referenceModel,
                    string.format("Relation '%s.%s' expects an entity from model '%s'",
                        tableName, key, relation.referenceTable))
                referenceValue = value[relation.referenceColumn]
                assert(referenceValue ~= nil,
                    string.format("Cannot assign an entity without '%s' to relation '%s.%s'",
                        relation.referenceColumn, tableName, key))
            end

            ModelClass.__newindex(self, relation.foreignKeyColumn, referenceValue)
            rawget(self, "_relations")[key] = value
            return
        end

        error(string.format("Couldn't set %s to %s on Entity; field or relation does not exist", key, value))
    end

    --- Attaches a materialized relation without changing or tracking its foreign key.
    --- @param entity ModelClass
    --- @param relationName string
    --- @param relatedEntity ModelClass?
    function ModelClass._setLoadedRelation(entity, relationName, relatedEntity)
        assert(getmetatable(entity) == ModelClass,
            string.format("Cannot load a relation onto an entity from another model"))

        local relation = assert(ModelClass.relations[relationName],
            string.format("Relation '%s.%s' does not exist", tableName, relationName))
        assert(relatedEntity == nil or getmetatable(relatedEntity) == relation.referenceModel,
            string.format("Relation '%s.%s' expects an entity from model '%s'",
                tableName, relationName, relation.referenceTable))

        rawget(entity, "_relations")[relationName] = relatedEntity
    end

    function ModelClass.asProxy()
        return entityProxy
    end

    function ModelClass.asOrderProxy()
        return orderProxies
    end

    function ModelClass.asRelationProxy()
        return relationProxy
    end

    return ModelClass
end
