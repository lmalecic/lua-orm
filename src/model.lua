local Model = {}
Model.__index = Model

function Model.new(tableName, columns)
	local self = setmetatable({}, Model)
	self.tableName = tableName
	self.columns = columns
	return self
end

return Model
