--- @class Field
--- @field name string
--- @field type Type
--- @field nullable boolean
--- @field isUnique boolean
--- @field defaultValue any
--- @field isPrimaryKey boolean
--- @field autoIncrement boolean
--- @field identityMode string
local Field = setmetatable({}, {
	--- @param name string
	--- @param type Type
	--- @return Field
	__call = function(self, name, type)
		return self.new(name, type)
	end
})
Field.__index = Field

Field.IdentityMode = {
	ALWAYS = "ALWAYS",
	BY_DEFAULT = "BY DEFAULT"
}

--- @param name string
--- @param type Type
--- @return Field
function Field.new(name, type)
	local self = setmetatable({}, Field)
	self.name = name
	self.type = type
	self.nullable = true
	self.isUnique = false
	self.defaultValue = nil
	self.isPrimaryKey = false
	self.autoIncrement = false
	self.identityMode = nil
	return self
end

function Field.raw(sql)
	return { __raw = true, value = sql }
end

function Field:notNull()
	self.nullable = false
	return self
end

function Field:null()
	self.nullable = true
	return self
end

function Field:unique()
	self.isUnique = true
	return self
end

function Field:default(value)
	self.defaultValue = value
	return self
end

--- @class PrimaryKeyOptions
--- @field autoIncrement boolean?
--- @field identity string?
--- @param opts PrimaryKeyOptions?
function Field:primaryKey(opts)
	opts = opts or {}
	self.isPrimaryKey = true
	self.nullable = false

	if opts.autoIncrement then
		if not self.type:supportsAutoIncrement() then
			error(self.type:toSql() .. " does not support auto increment!")
		end

		if opts.identity ~= nil then
			local found = false
			for _, v in pairs(Field.IdentityMode) do
				if v == opts.identity then
					found = true
					break
				end
			end

			assert(found, "Invalid identity mode: " .. opts.identity)
		end

		self.autoIncrement = true
		self.identityMode = opts.identity or Field.IdentityMode.ALWAYS
	end

	return self
end

return Field
