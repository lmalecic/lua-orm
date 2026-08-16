--- @class GeneratorReferenceable
--- @field toGeneratorReferenceString fun(self: GeneratorReferenceable): string

local Value = {}

--- @param value string | number | boolean | GeneratorReferenceable
function Value.valueToCode(value)
    if type(value) == "string" then
        return ("%q"):format(value)
    elseif type(value) == "number" then
        return ("%s"):format(value)
    elseif type(value) == "boolean" then
        return tostring(value)
    elseif type(value) == "table" then
        assert(value.toGeneratorReferenceString ~= nil, "Non-primitive values must implement toGeneratorReferenceString() method if you wish to use it in the migration generator")
        return value:toGeneratorReferenceString()
    end

    return value
end

function Value.equals(value1, value2)
    if value1 == value2 then -- this catches nil, strings, numbers, booleans, tables of equal references
        return true
    end

    if type(value1) == "table" and type(value2) == "table" then
        assert(value1.equals ~= nil, "Non-primitive values must implement equals()")
        return value1:equals(value2)
    end

    return false
end

return Value
