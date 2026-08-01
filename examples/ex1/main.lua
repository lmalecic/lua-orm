package.path = "./?.lua;./?/init.lua;" .. package.path
package.path = "./examples/ex1/?.lua;" .. package.path

local db = require("context")

local testSet = db.data.test
local anotherTestSet = db.data.test2

db.data.test:where(function(test)
	return test.id:eq(1)
end)
