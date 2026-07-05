local Type = require("src.types.type")

--- @class Text : Type
local Text = setmetatable({}, { __index = Type })
Text.__index = Text

function Text:formatDefault(value)
	assert(type(value) == "string", "TEXT default must be a string")
	return "'" .. value:gsub("'", "''") .. "'"
end

return setmetatable(Type.new("TEXT"), Text) --[[@as Text]]
