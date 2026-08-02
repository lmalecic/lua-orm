local ConstantNode = {}
ConstantNode.__index = ConstantNode

function ConstantNode.new(value)
	return setmetatable({
		value = value,
	}, ConstantNode)
end

return ConstantNode
