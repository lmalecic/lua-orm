local lfs = require("lfs")

local Connection = require("orm.connection")
local DataSet = require("orm.query.dataset")
local PgCompiler = require("orm.query.compiler.pg")
local MigrationGenerator = require("orm.migrations.generator")
local MigrationBuilder = require("orm.migrations.migration-builder")
local ChangeTracker = require("orm.change-tracking.tracker")
local EntityEntry = require("orm.change-tracking.entity-entry")
local Relation = require("orm.model.relation")
local ModelRelation = require("orm.model.model-relation")

--- @alias Schema ModelClass[]

--- @class DbConfig
--- @field host string
--- @field port integer?
--- @field database string
--- @field user string?
--- @field password string?
--- @field autoMigrate boolean?
--- @field migrationsDir string?
--- @field compiler any

--- @class DbContext
--- @field config DbConfig
--- @field connection Connection
--- @field _pgConnection Connection
--- @field schema Schema
--- @field modelClasses table<string, ModelClass>
--- @field data table<string, DataSet>
--- @field changeTracker ChangeTracker
local Context = {}
Context.__index = Context

function Context.new(config, schema)
    local self = setmetatable({}, Context)
    self.config = config or {}
    self.config.compiler = self.config.compiler or PgCompiler
    self.config.migrationsDir = self.config.migrationsDir or "migrations"

    self.connection = Connection.new(config, self.config.compiler)
    self._pgConnection = Connection.new({
        host = config.host,
        port = config.port,
        database = self.config.compiler.MAINTENANCE_DATABASE,
        user = config.user,
        password = config.password,
    }, self.config.compiler)

    self.schema = schema

    local data = {}
    local modelClasses = {}
    local dataSets = {}

    for _, ModelClass in ipairs(schema) do
        assert(not modelClasses[ModelClass.tableName], "Model " .. ModelClass.tableName .. " already exists")
        modelClasses[ModelClass.tableName] = ModelClass
    end

    ModelRelation.setResolutionKind(Relation.Kinds.BELONGS_TO)

    local resolvedBelongsTo, resolutionError = pcall(function()
        for _, ModelClass in ipairs(schema) do
            ModelClass.resolveRelations(modelClasses)
        end
    end)

    ModelRelation.setResolutionKind(nil)

    if not resolvedBelongsTo then
        error(resolutionError, 0)
    end

    for _, ModelClass in ipairs(schema) do
        for _, relation in pairs(ModelClass.relations) do
            if relation.kind ~= Relation.Kinds.BELONGS_TO then
                relation:resolve(ModelClass, modelClasses)

                local proxy = ModelClass.asRelationProxy().relationFieldProxies[relation.name]
                rawset(proxy, "fieldName", relation.sourceColumn)
                rawset(proxy, "referenceColumnName", relation.targetColumn)
            end
        end
    end

    for _, ModelClass in ipairs(schema) do
        dataSets[ModelClass.tableName] = DataSet.new(ModelClass, self)
    end

    self.modelClasses = modelClasses

    self.data = setmetatable(data, {
        __index = function(_, k)
            local modelClass = assert(modelClasses[k], "Invalid index on context.data; model " .. k .. " not found")
            return dataSets[modelClass.tableName]
        end,

        __newindex = function(_, _, _)
            error("Setting values on context.data is not allowed")
        end
    })

    self.changeTracker = ChangeTracker.new(self)

    if self.config.database then
        self:ensureDatabase()
        self:ensureMigrationHistoryTable()

        if self.config.autoMigrate then
            self:migrateUp()
        end
    end

    return self
end

function Context:getCompiler()
    return self.config.compiler.new(self.connection.client)
end

function Context:query(sql, ...)
    return self.connection:query(sql, ...)
end

function Context:query_array(sql, ...)
    return self.connection:query_array(sql, ...)
end

--- Runs callback atomically using this context's connection.
--- @param callback fun()
function Context:transaction(callback)
    self.connection:transaction(callback)
end

function Context:saveChanges()
    local added = self.changeTracker:entriesInState(EntityEntry.State.ADDED)
    local modified = self.changeTracker:entriesInState(EntityEntry.State.MODIFIED)
    local deleted = self.changeTracker:entriesInState(EntityEntry.State.DELETED)

    self:transaction(function()
        local compiler = self:getCompiler()

        for _, entry in ipairs(added) do
            local sql, params = compiler:compileInsert(entry)
            local result = self:query(sql, unpack(params))

            if result and result[1] then
                for fieldName, value in pairs(result[1]) do
                    rawget(entry.entity, "_attributes")[fieldName] = value
                end
            end
        end

        for _, entry in ipairs(modified) do
            local sql, params = compiler:compileUpdate(entry)
            self:query(sql, unpack(params))
        end

        for _, entry in ipairs(deleted) do
            local sql, params = compiler:compileDelete(entry)
            self:query(sql, unpack(params))
        end
    end)

    for _, entry in ipairs(added) do
        entry:acceptChanges()
    end

    for _, entry in ipairs(modified) do
        entry:acceptChanges()
    end

    for _, entry in ipairs(deleted) do
        self.changeTracker:detach(entry.entity)
    end
end

--- @param modelClass ModelClass
--- @param row table
function Context:_materialize(modelClass, row)
    row = self.connection:normalizeRow(row)

    local primaryKey = modelClass.primaryKey

    if primaryKey and row[primaryKey] ~= nil then
        local byModel = self.changeTracker.identityMap[modelClass]
        if byModel and byModel[row[primaryKey]] then
            return byModel[row[primaryKey]]
        end
    end

    local entity = modelClass.new(row, false)
    self.changeTracker:trackUnchanged(entity, modelClass)

    if primaryKey and row[primaryKey] ~= nil then
        local byModel = self.changeTracker.identityMap[modelClass] or {}
        byModel[row[primaryKey]] = entity
        self.changeTracker.identityMap[modelClass] = byModel
    end

    return entity
end

function Context:ensureDatabase()
    -- TODO: Replace with specific compiler implementation, rather than hardcoded postgres compiler
    local conn = self._pgConnection
    local result = conn:query(string.format([=[
        SELECT EXISTS (
            SELECT 1 FROM %s
            WHERE datname = $1
        );
    ]=], self.config.compiler.DATABASE_TABLE), self.config.database)

    local exists = result and result[1] and result[1].exists
    if not exists then
        conn:query(string.format("CREATE DATABASE %s", self.config.database))
    end

    conn:disconnect()
end

function Context:ensureMigrationHistoryTable()
    -- TODO: Replace with specific compiler implementation, rather than hardcoded postgres compiler
    local conn = self.connection

    -- [NOTE] If ever going back to this method through pg_catalog, make sure identifiers are escaped
    --
    -- local result = conn:query(string.format([=[
    --     SELECT EXISTS (
    --         SELECT 1 FROM %s.%s c
    --         JOIN %s.%s n ON n.%s = c.%s
    --         WHERE c.%s = $1 AND n.%s = $2 AND c.%s = $3
    --     );
    -- ]=],
    --     self.config.compiler.CATALOG_SCHEMA, self.config.compiler.RELATIONS_TABLE,
    --     self.config.compiler.CATALOG_SCHEMA, self.config.compiler.SCHEMAS_TABLE, self.config.compiler.OID_COLUMN, self.config.compiler.REL_NAMESPACE_COLUMN,
    --     self.config.compiler.REL_NAME_COLUMN, self.config.compiler.NAMESPACE_NAME_COLUMN, self.config.compiler.REL_KIND_COLUMN
    -- ), self.config.compiler.MIGRATION_HISTORY_TABLE, self.config.compiler.PUBLIC_SCHEMA, self.config.compiler.ORDINARY_TABLE)

    -- local exists = result and result[1] and result[1].exists
    -- if not exists then
    --     conn:query(string.format([=[
    --         CREATE TABLE %s.%s (
    --             version TEXT PRIMARY KEY,
    --             applied_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    --         )
    --     ]=], self.config.compiler.PUBLIC_SCHEMA, self.config.compiler.MIGRATION_HISTORY_TABLE))
    -- end

    conn:query(string.format([=[
        CREATE TABLE IF NOT EXISTS %s.%s (
            version TEXT PRIMARY KEY,
            applied_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    ]=],
        conn.client:escape_identifier(self.config.compiler.PUBLIC_SCHEMA),
        conn.client:escape_identifier(self.config.compiler.MIGRATION_HISTORY_TABLE))
    )

    conn:disconnect()
end

function Context:_loadMigrations()
    local migrations = {}

    local migrationsNamespace = self.config.migrationsDir:gsub("/", ".")
    for file in lfs.dir(self.config.migrationsDir) do
        if file:match("%.lua$") then
            local moduleName = file:sub(1, -5)
            local migration = require(migrationsNamespace .. "." .. moduleName)
            assert(migration.version, string.format("Migration %s is missing a version field", moduleName))
            assert(migration.version == moduleName, string.format("Migration version mismatch: expected %s from file name, got %s",
                moduleName,
                migration.version))
            assert(migration.up ~= nil, string.format("Migration %s is missing an up function", moduleName))
            assert(migration.down ~= nil, string.format("Migration %s is missing a down function", moduleName))
            migration.moduleName = moduleName
            table.insert(migrations, migration)
        end
    end

    table.sort(migrations, function(a, b)
        return a.version < b.version
    end)

    return migrations
end

function Context:_getAppliedMigrationVersions()
    local conn = self.connection
    local result = conn:query(string.format(
        "SELECT version FROM %s.%s;",
        conn.client:escape_identifier(self.config.compiler.PUBLIC_SCHEMA),
        conn.client:escape_identifier(self.config.compiler.MIGRATION_HISTORY_TABLE)
    ))

    local applied = {}
    for _, migration in ipairs(result) do
        applied[migration.version] = true
    end

    return applied
end

--- Attempts to migrate the database to the latest version.
--- On success, returns a list of applied migration versions, otherwise errors.
--- @return string[]
function Context:migrateUp()
    -- Read applied version from db and return a set of strings of the versions
    -- Read migration files from disk, extract each version
    -- Compare versions and construct an ordered pending list, sorted by ascending version number
    -- Apply each migration in the ordered pending list
    --  1. require the migration file
    --  2. begin transaction, call the up function with the migrationBuilder
    --  3. on success, insert into the migration history table, commit transaction
    -- Stop on first failure

    local conn = self.connection

    local alreadyApplied = self:_getAppliedMigrationVersions()
    local migrations = self:_loadMigrations()

    local pending = {}
    for _, migration in ipairs(migrations) do
        if not alreadyApplied[migration.version] then
            table.insert(pending, migration)
        end
    end

    if #pending == 0 then
        return {}
    end

    local applied = {}
    local ok, err = pcall(conn.transaction, conn, function()
        for _, migration in ipairs(pending) do
            local migrationBuilder = MigrationBuilder.new(self)
            migration.up(migrationBuilder)

            conn:query(table.concat(migrationBuilder.query))

            conn:query(string.format(
                "INSERT INTO %s.%s (version) VALUES ($1);",
                conn.client:escape_identifier(self.config.compiler.PUBLIC_SCHEMA),
                conn.client:escape_identifier(self.config.compiler.MIGRATION_HISTORY_TABLE)
            ), migration.version)

            table.insert(applied, migration.version)
        end
    end)

    if not ok then
        error("Failed to migrate: " .. err .. "\nAttempted: " .. table.concat(applied, ", "))
    end

    return applied
end

--- @param targetVersion string
--- @return string[]
function Context:migrateDown(targetVersion)
    assert(targetVersion, "Failed to revert migration: targetVersion parameter is required")

    local conn = self.connection
    local alreadyApplied = self:_getAppliedMigrationVersions()

    assert(alreadyApplied[targetVersion], string.format("Failed to revert migration: Migration %s is not applied", targetVersion))

    local migrations = self:_loadMigrations()

    local targetExists = false
    for _, migration in ipairs(migrations) do
        if migration.version == targetVersion then
            targetExists = true
            break
        end
    end

    assert(targetExists, string.format("Failed to revert migration: Migration %s not found", targetVersion))

    local toRevert = {}
    for i, migration in ipairs(migrations) do
        if migration.version == targetVersion then
            toRevert = { unpack(migrations, i + 1) }
            break
        end
    end

    if #toRevert == 0 then
        print("No migrations to revert")
        return {}
    end

    local reverted = {}
    local ok, err = pcall(conn.transaction, conn, function()
        for i = #toRevert, 1, -1 do -- we doin it backwards oh yeah baby (softver inginir momnt)
            local migration = toRevert[i]
            local migrationBuilder = MigrationBuilder.new(self)
            migration.down(migrationBuilder)

            conn:query(table.concat(migrationBuilder.query))
            conn:query(string.format(
                "DELETE FROM %s.%s WHERE version = $1",
                conn.client:escape_identifier(self.config.compiler.PUBLIC_SCHEMA),
                conn.client:escape_identifier(self.config.compiler.MIGRATION_HISTORY_TABLE)
            ), migration.version)

            table.insert(reverted, migration)
        end
    end)

    if not ok then
        error(string.format("Failed to revert to migration %s: %s", targetVersion, err))
    end

    return reverted
end

return Context
