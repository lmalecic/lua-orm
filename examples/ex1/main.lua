package.path = "./?.lua;./?/init.lua;" .. package.path
package.path = "./examples/ex1/?.lua;" .. package.path
package.cpath = package.cpath .. ";/usr/local/lib/lua/5.1/?.dylib"

local dbg = require("emmy_core")
dbg.tcpListen("127.0.0.1", 9966)
--dbg.waitIDE()

local spec = require("orm.query.specification")
local db = require("context")

local testSet = db.data.test
local anotherTestSet = db.data.test2

db.data.test:where(function(test)
    return spec.and_(test.id:equals(1), spec.or_(test.text:equals("BABA"), test.char:equals("brah")))
end):orderBy(function(test)
    return test.created_at:asc(), test.id:desc()
end):all()

print("Transaction test:")
db:transaction(function()
    db:query("CREATE TABLE tranTest (id INT PRIMARY KEY, text TEXT NOT NULL)")
    db:query("INSERT INTO tranTest (id, text) VALUES (1)")
end) -- Should fail
