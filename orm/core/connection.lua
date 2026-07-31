local pgmoon = require("pgmoon")

--- @class Connection
--- @field client any
--- @field _connected boolean
local Connection = {}
Connection.__index = Connection

--- @param config DbConfig
--- @return Connection
function Connection.new(config)
    assert(type(config) == "table", "Connection config must be a table")
    local self = setmetatable({}, Connection)
    self.client = pgmoon.new(config)
    self._connected = false
    return self
end

function Connection:connect()
    if self._connected then
        return true
    end
    local ok, err = self.client:connect()
    if not ok then
        error("Failed to connect to database: " .. tostring(err))
    end
    self._connected = true
    return true
end

function Connection:query(sql, params)
    self:connect()
    local result, err = self.client:query(sql, params)
    if not result then
        error("Database query failed: " .. tostring(err))
    end
    return result
end

return Connection
