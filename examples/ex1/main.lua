package.path = "./?.lua;./?/init.lua;" .. package.path
package.path = "./examples/ex1/?.lua;" .. package.path

local spec = require("orm.query.specification")
local db = require("context")

local testSet = db.data.test
local anotherTestSet = db.data.test2

db.data.test:where(function(test)
    return spec.and_(test.id:equals(1), spec.or_(test.text:equals("BABA"), test.char:equals("brah")))
end):orderBy(function(test)
    return test.created_at:asc(), test.id:desc()
end):all()
