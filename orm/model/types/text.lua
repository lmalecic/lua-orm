local Type = require("orm.model.types.type")

--- @class Text : Type
local Text = setmetatable({}, { __index = Type })
Text.__index = Text
Text.class = Text
Text.super = Type
Text.typeName = "Text"

function Text.new()
	return setmetatable(Type.new("TEXT"), Text) --[[@as Text]]
end

--- @param value string
function Text:formatDefault(value)
    assert(type(value) == "string", "TEXT default must be a string")
    return "'" .. value:gsub("'", "''") .. "'"
end

function Text:equals(other)
    if other == nil then
        return false
    end

    if self == other then
        return true
    end

    if getmetatable(self) == getmetatable(other) then
        return true
    end

    return false
end

return Text.new()
