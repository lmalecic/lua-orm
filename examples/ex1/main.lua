package.path = "./?.lua;./?/init.lua;" .. package.path
package.path = "./examples/ex1/?.lua;" .. package.path

local db = require("context")
local Orm = require("orm")

local filter = Orm.Query
    .col("test.id")
    :gt(0)
    :and_(Orm.Query.col("test.text"):ne(nil))

local whereSql, params = Orm.Query.compileWhere(filter)
print(whereSql)
for i, value in ipairs(params) do
    print(i, value)
end

local testSet = db.test
local anotherTestSet = db.test2
print(testSet ~= nil, anotherTestSet ~= nil)
