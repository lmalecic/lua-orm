package.path = "./?.lua;./?/init.lua;" .. package.path
package.path = "./examples/ex1/?.lua;" .. package.path

local query = require("orm.query")
local db = require("context")

local testSet = db.data.test
local anotherTestSet = db.data.test2

db.data.test:where(function(test)
    return query.and_(test.id:equals(1), query.or_(test.text:equals("BABA"), test.char:equals("brah")))
end)
