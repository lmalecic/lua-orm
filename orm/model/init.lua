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
--- @field _setLoadedRelation fun(entity: ModelClass, relationName: string, relatedValue: any)
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

        local reservedRelation = relationsByForeignKey[field.name]
        assert(not reservedRelation or reservedRelation.sourceField == field,
            string.format("Field '%s' conflicts with the generated foreign-key field for relation '%s.%s'",
                field.name, tableName, reservedRelation and reservedRelation.name or "?"))

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
            _loadedRelations = {},
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

    local function removeEntity(values, entity)
        for i = #values, 1, -1 do
            if values[i] == entity then
                table.remove(values, i)
                return
            end
        end
    end

    local function containsEntity(values, entity)
        for _, value in ipairs(values) do
            if value == entity then
                return true
            end
        end
        return false
    end

    local function fixupInverseRelations(entity, relation, oldTarget, newTarget)
        local targetModel = relation.targetModel
        if not targetModel then
            return
        end

        for _, inverse in pairs(targetModel.relations) do
            if inverse.kind ~= Relation.Kinds.BELONGS_TO
                and inverse.targetModel == relation.sourceModel
                and inverse.sourceColumn == relation.targetColumn
                and inverse.targetColumn == relation.sourceColumn then
                if oldTarget and rawget(oldTarget, "_loadedRelations")[inverse.name] then
                    if inverse.kind == Relation.Kinds.HAS_ONE then
                        if rawget(oldTarget, "_relations")[inverse.name] == entity then
                            rawget(oldTarget, "_relations")[inverse.name] = nil
                        end
                    else
                        removeEntity(rawget(oldTarget, "_relations")[inverse.name], entity)
                    end
                end

                if newTarget and rawget(newTarget, "_loadedRelations")[inverse.name] then
                    if inverse.kind == Relation.Kinds.HAS_ONE then
                        local previous = rawget(newTarget, "_relations")[inverse.name]
                        if previous and previous ~= entity then
                            assert(relation.sourceField.nullable,
                                string.format("Cannot replace required relation '%s.%s'",
                                    targetModel.tableName, inverse.name))
                            previous[relation.sourceColumn] = nil
                        end
                        rawget(newTarget, "_relations")[inverse.name] = entity
                    else
                        local values = rawget(newTarget, "_relations")[inverse.name]
                        if not containsEntity(values, entity) then
                            table.insert(values, entity)
                        end
                    end
                end
            end
        end
    end

    local function setTargetOwningRelation(relation, target, owner)
        for _, owningRelation in pairs(relation.targetModel.relations) do
            if owningRelation.kind == Relation.Kinds.BELONGS_TO
                and owningRelation.sourceColumn == relation.targetColumn
                and owningRelation.targetModel == ModelClass
                and owningRelation.targetColumn == relation.sourceColumn then
                local previousOwner = rawget(target, "_relations")[owningRelation.name]
                if previousOwner ~= owner then
                    fixupInverseRelations(target, owningRelation, previousOwner, owner)
                end
                relation.targetModel._setLoadedRelation(target, owningRelation.name, owner)
            end
        end
    end

    local function clearInverseTarget(relation, target)
        assert(relation.targetField.nullable,
            string.format("Cannot remove an entity from required relation '%s.%s'",
                tableName, relation.name))
        target[relation.targetColumn] = nil
        setTargetOwningRelation(relation, target, nil)
    end

    local function assignHasOneRelation(self, relation, value)
        assert(relation.sourceField and relation.targetField and relation.targetModel,
            string.format("Relation '%s.%s' has not been resolved by a context", tableName, relation.name))

        local loadedRelations = rawget(self, "_loadedRelations")
        local entry = rawget(self, "_entry")
        assert(loadedRelations[relation.name] or not entry or entry.state == "ADDED",
            string.format("Relation '%s.%s' must be loaded before it can be replaced",
                tableName, relation.name))

        local sourceValue = self[relation.sourceColumn]
        assert(sourceValue ~= nil,
            string.format("Cannot assign relation '%s.%s' while source field '%s' is nil",
                tableName, relation.name, relation.sourceColumn))

        assert(value == nil or getmetatable(value) == relation.targetModel,
            string.format("Relation '%s.%s' expects an entity from model '%s'",
                tableName, relation.name, relation.referenceTable))

        local previous = rawget(self, "_relations")[relation.name]
        if previous and previous ~= value then
            clearInverseTarget(relation, previous)
        end
        if value then
            value[relation.targetColumn] = sourceValue
            setTargetOwningRelation(relation, value, self)
        end

        rawget(self, "_relations")[relation.name] = value
        loadedRelations[relation.name] = true
    end

    local function propagateLoadedInverseSourceChange(self, fieldName, newValue)
        local loadedRelations = rawget(self, "_loadedRelations")

        for _, relation in pairs(ModelClass.relations) do
            if relation.kind ~= Relation.Kinds.BELONGS_TO and relation.sourceColumn == fieldName and loadedRelations[relation.name] then
                if relation.kind == Relation.Kinds.HAS_ONE then
                    assert(newValue ~= nil or relation.targetField.nullable,
                        string.format("Cannot clear '%s.%s' while required relation '%s.%s' is loaded",
                            tableName, fieldName, tableName, relation.name))

                    local target = rawget(self, "_relations")[relation.name]
                    if target then
                        target[relation.targetColumn] = newValue
                        setTargetOwningRelation(relation, target, self)
                    end
                else
                    rawget(self, "_relations")[relation.name] = nil
                    loadedRelations[relation.name] = false
                end
            end
        end
    end

    function ModelClass.__newindex(self, key, value)
        local field = ModelClass.fieldsByName[key]
        if field then
            local attributes = rawget(self, "_attributes")
            local previousValue = attributes[key]
            if previousValue == value then
                return
            end

            local relation = relationsByForeignKey[key]
            local previousTarget = relation and rawget(self, "_relations")[relation.name] or nil

            attributes[key] = value
            propagateLoadedInverseSourceChange(self, key, value)

            if relation then
                rawget(self, "_relations")[relation.name] = nil
                rawget(self, "_loadedRelations")[relation.name] = false
                fixupInverseRelations(self, relation, previousTarget, nil)
            end

            local entry = rawget(self, "_entry")
            if entry then
                entry:recordChange(key, previousValue, value)
            end
            return
        end

        local relation = ModelClass.relations[key]
        if relation then
            if relation.kind == Relation.Kinds.HAS_MANY then
                error(string.format("HAS_MANY relation '%s.%s' is read-only; update the target BELONGS_TO relation instead",
                    tableName, key))
            elseif relation.kind == Relation.Kinds.HAS_ONE then
                assignHasOneRelation(self, relation, value)
                return
            end

            assert(relation.sourceField and relation.targetModel,
                string.format("Relation '%s.%s' has not been resolved by a context", tableName, key))
            assert(value ~= nil or relation.sourceField.nullable,
                string.format("Cannot clear required relation '%s.%s'", tableName, key))

            local referenceValue = nil
            if value ~= nil then
                assert(type(value) == "table" and getmetatable(value) == relation.targetModel,
                    string.format("Relation '%s.%s' expects an entity from model '%s'",
                        tableName, key, relation.referenceTable))
                referenceValue = value[relation.targetColumn]
                assert(referenceValue ~= nil,
                    string.format("Cannot assign an entity without '%s' to relation '%s.%s'",
                        relation.targetColumn, tableName, key))
            end

            local previousTarget = rawget(self, "_relations")[key]
            ModelClass.__newindex(self, relation.sourceColumn, referenceValue)
            rawget(self, "_relations")[key] = value
            rawget(self, "_loadedRelations")[key] = true
            fixupInverseRelations(self, relation, previousTarget, value)
            return
        end

        error(string.format("Couldn't set %s to %s on Entity; field or relation does not exist", key, value))
    end

    --- Attaches a materialized relation without changing or tracking its foreign key.
    --- @param entity ModelClass
    --- @param relationName string
    --- @param relatedValue any
    function ModelClass._setLoadedRelation(entity, relationName, relatedValue)
        assert(getmetatable(entity) == ModelClass,
            string.format("Cannot load a relation onto an entity from another model"))

        local relation = assert(ModelClass.relations[relationName],
            string.format("Relation '%s.%s' does not exist", tableName, relationName))

        if relation.kind == Relation.Kinds.HAS_MANY then
            assert(type(relatedValue) == "table" and getmetatable(relatedValue) == nil,
                string.format("Relation '%s.%s' expects an array", tableName, relationName))
            for i, relatedEntity in ipairs(relatedValue) do
                assert(getmetatable(relatedEntity) == relation.targetModel,
                    string.format("Relation '%s.%s' item %d must be from model '%s'",
                        tableName, relationName, i, relation.referenceTable))
            end
        else
            assert(relatedValue == nil or getmetatable(relatedValue) == relation.targetModel,
                string.format("Relation '%s.%s' expects an entity from model '%s'",
                    tableName, relationName, relation.referenceTable))
        end

        rawget(entity, "_relations")[relationName] = relatedValue
        rawget(entity, "_loadedRelations")[relationName] = true
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
