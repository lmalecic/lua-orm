local pgmoon = require("pgmoon")

--- @class Connection
--- @field client table
--- @field connected boolean
local Connection = {}
Connection.__index = Connection

--- @class ConnectionConfig
--- @field host string
--- @field port integer?
--- @field database string
--- @field user string?
--- @field password string?
--- @field autoMigrate boolean?

--- @param config ConnectionConfig
--- @return Connection
function Connection.new(config)
    assert(type(config) == "table", "Connection config must be a table!")
    local self = setmetatable({}, Connection)
    self.client = pgmoon.new(config)
    self.connected = false
    return self
end

--- @return boolean
function Connection:connect()
    if self.connected then
        return true
    end

    local ok, err = self.client:connect()
    if not ok then
        error("Failed to connect to database: " .. tostring(err))
    end

    self.connected = true
	return true
end

--- @param sql string
--- @return table[]
function Connection:query(sql, ...)
    self:connect()

    local result, err = self.client:query(sql, ...)
    if not result then
        error("Database query failed: " .. tostring(err))
    end

    return result
end

return Connection
