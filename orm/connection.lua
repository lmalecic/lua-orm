local pgmoon = require("pgmoon")

--- @class Connection
--- @field client table
--- @field compiler any
--- @field connected boolean
--- @field _inTransaction boolean
local Connection = {}
Connection.__index = Connection

--- @param config DbConfig
--- @param compilerClass any
--- @return Connection
function Connection.new(config, compilerClass)
    assert(type(config) == "table", "Connection config must be a table!")
    compilerClass = compilerClass or config.compiler
    assert(compilerClass and type(compilerClass.new) == "function", "Connection requires a compiler class")

    local self = setmetatable({}, Connection)
    self.client = pgmoon.new(config)
    self.compiler = compilerClass.new(self.client)
    self.connected = false
    self._inTransaction = false
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

function Connection:disconnect()
    if not self.connected then
        return
    end

    local success, err = self.client:disconnect()
    if not success then
        error("Failed to disconnect from database: " .. tostring(err))
    end

    self.connected = false
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

local function traceback(err)
    return debug.traceback(tostring(err), 2)
end

--- @param callback fun()
function Connection:transaction(callback)
    assert(type(callback) == "function", "Transaction callback must be a function")
    assert(not self._inTransaction, "Nested transactions are not supported")

    self:query(self.compiler:compileBeginTransaction())
    self._inTransaction = true

    local ok, errorOrNil = xpcall(callback, traceback)

    if ok then
        local committed, commitError = pcall(function()
            self:query(self.compiler:compileCommitTransaction())
        end)

        if committed then
            self._inTransaction = false
            return
        end

        pcall(function()
            self:query(self.compiler:compileRollbackTransaction())
        end)
        self._inTransaction = false

        error(commitError, 0)
    end

    pcall(function()
        self:query(self.compiler:compileRollbackTransaction())
    end)
    self._inTransaction = false

    error(errorOrNil, 0)
end

return Connection
