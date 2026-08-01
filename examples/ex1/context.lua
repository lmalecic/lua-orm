local DbContext = require("orm.context")
local lfs = require("lfs")

local config = {
    host = os.getenv("PGHOST") or "127.0.0.1",
    port = tonumber(os.getenv("PGPORT")) or 5432,
    database = os.getenv("PGDATABASE") or "medix",
    user = os.getenv("PGUSER") or "medix",
    password = os.getenv("PGPASSWORD") or "medix",
    autoMigrate = false,
}

local schema = {}

for file in lfs.dir("examples/ex1/models") do
    if file:match("%.lua$") then
        local moduleName = file:sub(1, -5)
        table.insert(schema, require("models." .. moduleName))
    end
end

return DbContext.new(config, schema)
