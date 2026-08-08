local OrderNode = {}
OrderNode.__index = OrderNode
OrderNode.isOrderNode = true

OrderNode.Direction = {
    ASC = "ASC",
    DESC = "DESC",
}

function OrderNode.new(fieldProxy, direction)
    assert(OrderNode.Direction[direction] ~= nil, "Invalid direction: " .. tostring(direction))
    return setmetatable({
        fieldProxy = fieldProxy,
        direction = direction,
    }, OrderNode)
end

return OrderNode
