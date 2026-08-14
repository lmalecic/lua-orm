local OrderNode = require("orm.query.node.order")

--- @class OrderFieldProxy
--- @field table string
--- @field column string
local OrderFieldProxy = {}
OrderFieldProxy.__index = OrderFieldProxy

function OrderFieldProxy.new(tableName, columnName)
    return setmetatable({
        table = tableName,
        column = columnName
    }, OrderFieldProxy)
end

function OrderFieldProxy:asc()
    return OrderNode.new(self, OrderNode.Direction.ASC)
end

function OrderFieldProxy:desc()
    return OrderNode.new(self, OrderNode.Direction.DESC)
end

return OrderFieldProxy
