local lfs = require("lfs")

local MIGRATION_TEMPLATE = [=[
    local Migration = {}
    Migration.version = "%s"

    --- @param migrationBuilder MigrationBuilder
    function Migration.up(migrationBuilder)
        %s
    end

    --- @param migrationBuilder MigrationBuilder
    function Migration.down(migrationBuilder)
        %s
    end

    return Migration
]=]

local Requires = {
    TYPES = 'local Types = require("orm.model.types")',
    CONSTRAINT = 'local Constraint = require("orm.model.constraint")',
    ALTER = 'local Alter = require("orm.migrations.alter")',
    CURRENT_TIMESTAMP = 'local CurrentTimestamp = require("orm.model.expressions.current-timestamp")'
}

local MigrationBuilderMethods = {
    CREATE_TABLE = 'migrationBuilder:createTable("%s", { %s })',
    DROP_TABLE = 'migrationBuilder:dropTable("%s")',
    ALTER_TABLE = 'migrationBuilder:alterTable("%s", { %s })'
}

--- @param str string
local function toSnakeCase(str)
    return str:lower()
        :gsub("[^%w]+", "_") -- non-alphanumeric to underscore
        :gsub("^_+", ""):gsub("_+$", "") -- trim leading/trailing underscores
end

--- @return string
local function timestamp()
    return tostring(os.date("%Y%m%d%H%M%S"))
end

local function ensureDirRecursive(path)
  local accum = ""
  for segment in path:gmatch("[^/]+") do
    accum = accum == "" and segment or (accum .. "/" .. segment)
    local attr = lfs.attributes(accum)
    if not attr then
      local ok, err = lfs.mkdir(accum)
      if not ok then
        return nil, err
      end
    elseif attr.mode ~= "directory" then
      return nil, accum .. " exists and is not a directory"
    end
  end
  return true
end

local MigrationGenerator = {}

--- @class MigrationGeneratorOptions
--- @field migrationsDirectory string?

--- @param name string
--- @param options MigrationGeneratorOptions
function MigrationGenerator.generate(name, options)
    options = options or {}

    local dir = options.migrationsDirectory
    ensureDirRecursive(dir)

    local slug = toSnakeCase(name)
    assert(slug ~= "", string.format("Migration name '%s' produced an empty slug after sanitization", name))

    local version = string.format("%s_%s", timestamp(), slug)
    local filename = string.format("%s.lua", version)
    local path = string.format("%s/%s", dir, filename)

    local file, open_err = io.open(path, "w")
    assert(file, string.format("Failed to create migration file '%s': %s", path, open_err))

    local requires = {}
    local up = {}
    local down = {}



    local fileContent = MIGRATION_TEMPLATE:format(version, table.concat(up, "\n"), table.concat(down, "\n"))
    if #requires > 0 then
        fileContent = table.concat(requires, "\n") .. "\n" .. fileContent
    end

    file:write(fileContent)
    file:close()

    return path
end

return MigrationGenerator
