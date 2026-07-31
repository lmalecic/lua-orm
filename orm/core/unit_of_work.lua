--- @class UnitOfWork
local UnitOfWork = {}
UnitOfWork.__index = UnitOfWork

function UnitOfWork.new()
    return setmetatable({}, UnitOfWork)
end

function UnitOfWork:saveChanges()
    -- Stub for future change tracking persistence.
end

return UnitOfWork
