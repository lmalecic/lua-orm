local Value = {}

local NIL = {
    type = "nil"
}

function Value.encode(value)
    return value == nil and NIL or value
end

function Value.decode(value)
    if value == NIL then
        return nil
    end
    return value
end

return Value
