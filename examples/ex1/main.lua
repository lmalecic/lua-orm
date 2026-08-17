package.path = "./?.lua;./?/init.lua;" .. package.path
package.path = "./examples/ex1/?.lua;" .. package.path

local MigrationGenerator = require("orm.migrations.generator")
local spec = require("orm.query.specification")
local db = require("context")

-- local generator = MigrationGenerator.new("Initial Migration", db, { migrationsDirectory = db.config.migrationsDir })
-- generator:generate()

-- db:migrateUp()

-- local test2_notincluded = db.data.test2:find(2)
-- local test2 = db.data.test2:include(function(test2)
--     return test2.test
-- end):find(2)

-- local test = db.data.test:include(function(test)
--     return test.test2s
-- end):find(14)

-- test2.test.text = "Modified through relational property"
-- db:saveChanges()

-- require("orm.migrations").executeUp(db, require("migrations.0-initial-migration"))

-- local tests = db.data.test:all()

-- local test = db.data.test:first()
-- test.text = "Modified"

-- local test2 = db.data.test:find(14)
-- test2.text = "Modified"
-- test2.decimal = 67
-- -- test2.text = "Default text"

-- local Test = require("models.Test")

-- local newTest = Test.new()
-- newTest.text = "Added"
-- db.data.test:add(newTest)

-- db:saveChanges()

--- Test to see if query_array would work for queries with include:
-- local res1 = db.connection:query_array([=[
--     select * from test2
--     inner join test on test2.test_id = test.id;
-- ]=])
-- -----------

-- db.data.test2:include(function(test2)
--     return test2.test
-- end)


-- db.data.test:where(function(test)
--     return spec.and_(test.id:equals(1), spec.or_(test.text:equals("BABA"), test.char:equals("brah")))
-- end):orderBy(function(test)
--     return test.created_at:asc(), test.id:desc()
-- end):all()

-- print("Transaction test:")
-- db:transaction(function()
--     db:query("CREATE TABLE tranTest (id INT PRIMARY KEY, text TEXT NOT NULL)")
--     db:query("INSERT INTO tranTest (id) VALUES (1)")
-- end) -- Should fail because tranTest.text has not null constraint

-- require("orm.migrations").executeUp(db, require("migrations.0-initial-migration"))
-- require("orm.migrations").executeUp(db, require("migrations.1-migration"))
-- require("orm.migrations").executeUp(db, require("migrations.2-migration"))
