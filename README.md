# Lua ORM
An Object Relational Mapper library for Lua 5.1 made for a university course project. Currently supports only **PostgreSQL**.

## How to install?
Download the repository, in the repository directory run:
```
luarocks make
```

You can also manually extract the ``/orm`` directory and place it wherever you want in your project, but you'll have to specify the include path and still install the luarocks dependencies listed in ``/orm-dev-1.rockspec``

## Basic usage
The library is designed for usage with a code-first approach, but it will still work if you already have a database and have defined the schema correctly.
I recommend organizing your schema and context in separate files, as well as defining each model in a single lua file and fetching it dynamically, Lua ORM uses LuaFileSystem internally, so you can use it too.

### Example
```lua
-- context.lua
local DbContext = require("orm.context")
local lfs = require("lfs")

--- @type DbConfig
local config = {
    -- never hardcode secrets, use environment variables
    host = os.getenv("PGHOST") or "127.0.0.1",
    port = tonumber(os.getenv("PGPORT")) or 5432,
    database = os.getenv("PGDATABASE") or "yourDatabaseHere",
    user = os.getenv("PGUSER") or "user",
    password = os.getenv("PGPASSWORD") or "password",
    autoMigrate = false, -- optional, false by default
    migrationsDir = "examples/ex1/migrations" -- optional, defaults to /migrations
}

local schema = {}

-- Fetch the models from /models
for file in lfs.dir("models") do
    if file:match("%.lua$") then
        local moduleName = file:sub(1, -5)
        table.insert(schema, require("models." .. moduleName))
    end
end

return DbContext.new(config, schema)
```

```lua
-- models/Test.lua
local Model = require("orm.model")
local Types = require("orm.model.types")
local CurrentTimestamp = require("orm.model.expressions.current-timestamp")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local Test = Model("test", {
    { "id",             Types.Int,          Constraint.PrimaryKey, Constraint.AutoIncrement() },
	{ "text",           Types.Text,         Constraint.Default("Default text"),         Constraint.NotNull },
	{ "created_at",     Types.Timestamp,    Constraint.Default(CurrentTimestamp(3)),    Constraint.NotNull },
	{ "created_at_tz",  Types.TimestampTz,  Constraint.Default(CurrentTimestamp()),     Constraint.NotNull },
	{ "char",           Types.Char(20) },
	{ "varchar",        Types.Varchar(50) },
	{ "decimal",        Types.Decimal(),    Constraint.Default(67694142) },
    { "float",         Types.Float },
    { "newColumn", Types.Int },

    { "test2s", Relation.hasMany("test2", "test_id") }
})

return Test
```

```lua
-- models/Test2.lua
local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")

local Test2 = Model("test2", {
    { "id",             Types.Int,          Constraint.PrimaryKey, Constraint.AutoIncrement() },
	{ "char",           Types.Char(20) },
	{ "varchar",        Types.Varchar(50) },
	{ "decimal",        Types.Decimal(),    Constraint.Default(67694142) },
    { "float",   Types.Float },

    { "test", Relation.belongsTo("test", "id") }
})

return Test2
```
To use the Context you just defined:
```lua
local db = require("context")
db.data.test:first() -- returns the first Test entity
db.data.test2:all() -- returns all Test2 entities
-- other code...
```

### Accessing entities
Entities are accessed by indexing ``context.data`` with the defined model name. Indexing an invalid model will error and adding a new index to the data field will error.
This returns a ``DataSet`` object with various methods for querying the entity. All of these methods return a ``Query`` object, except for ``add()``, ``remove()`` and finalizing methods (``all()``, ``first()`` or ``find()``).

### Filtering
``DataSet`` has a ``where(expression)`` method used to filter the query. This modifies the query, adding a ``WHERE`` statement to the query.
Expression must be a function which takes a proxy as the only parameter that provides the model's fields with methods for filtering and must return the result of the filtering method or a ``Specification`` object, for example:
```lua
db.data.test:where(function(test)
  return test.id:greaterThan(5)
end)
```
or if you need a more complex condition that uses and/or, use the ``Specification`` class:
```lua
local spec = require("orm.query.specification")

db.data.test:where(function(test)
  return spec.and_(
    test.id:equals(1),
    spec.or_(
      test.text:equals("foo"),
      test.char:equals("bar")
    )
  )
end)
```

### Ordering
Similar to ``where(expression)``, to fetch an ordered result, use ``orderBy(expression)``. The expression parameter here is a function just like in ``where()``, but it has fields with ordering methods and can return multiple nodes for complex ordering, for example:
```lua
db.data.test:orderBy(function(test)
  return test.created_at:asc(), test.id:desc()
end)
```

### Query mixing
Because ``DataSet`` methods return ``Query`` objects, and ``Query`` methods return the same modified object, you can stack as many of the methods as you want. The query will only ever be executed once you call a finalizing method.
```lua
db.data.test:where(function(test)
    return spec.and_(
        test.id:equals(1),
        spec.or_(
            test.text:equals("foo"),
            test.char:equals("bar")
        )
    )
end):orderBy(function(test)
    return test.created_at:asc(), test.id:desc()
end):all() -- all() finalizes and executes the query, returns the result returned by the database converted to Entities
```

### Entities and change tracking
Entities are returned by the finalizing methods, they are a simple dictionary where keys are the defined columns of the model and values are lua values.
Changing the values of any entity fields triggers **change tracking**. To save any changes you must call ``db:saveChanges()``, otherwise the changes aren't sent to the database.

#### Relational fields
A model 'A' may have a foreign key pointing to another model 'B'. To fetch that model 'B' you can use a relational field property defined on model 'A'.
To define a relational property, use the ``Relation`` class methods.

##### ``belongsTo(referenceTable, referenceTableColumn, options)``
Defines a N-1 relation where ``referenceTable`` is a string that must match the name of the table that owns the relation and ``referenceTableColumn`` is the column in ``referenceTable`` which is used for the reference.
This method automatically generates the foreign key column, you do not need to manually create one.

The following options are available:
| Option | Type | Default | Description |
| --- | --- | --- | --- |
| ``foreignKeyColumnName`` | ``string`` | ``{referenceTable}_{referenceTableColumn}`` | Defines the foreign key column name |

##### ``hasOne(referenceTable, targetForeignKeyColumn, options)``
Defines a 1-1 relation where ``referenceTable`` is a string that must match the name of the table that has the foreign key and ``targetForeignKeyColumn`` is the foreign key column of ``referenceTable`` used for the reference.
The ``targetForeignKey`` column must be defined in ``referenceTable``, otherwise it will throw an error.

The following options are available:
| Option | Type | Default | Description |
| --- | --- | --- | --- |
| ``localColumn`` | ``string`` | Primary key column name | Specifies which column on the current model is referenced by the related model's foreign key column |

##### ``hasMany(referenceTable, targetForeignKey, options``
Same as ``hasOne()`` but for 1-N.

**IMPORTANT:** a hasMany relational field is currently read-only, no change tracking is implemented for it.

### Migrations
#### Generating migrations
To generate migrations, use the ``MigrationGenerator`` object and run it as a separate script:
```lua
local MigrationGenerator = require("orm.migrations.generator")

local db = require("context")

local generator = MigrationGenerator.new("Initial Migration", db)
generator:generate()
```
This will create:
- a directory specified in ``DbConfig.migrationsDir`` (or ``/migrations`` by default) if it doesn't exist
- a migration Lua file with a version and up() and down() functions inside that directory
- a ``_schema_snapshot.lua`` file containing the latest schema snapshot, used to diff against

It is recommended to check the migration files to verify that they are correct.

#### Migrating up
Once you have your migration files generated (or created manually), migrate the database by simply running:
```lua
local db = require("context")
db:migrateUp()
```

#### Migrating down
If you ever wish to "downgrade" your database to a previous migration, you may use ``db:migrateDown(version)``. This currently allows for downgrading to a specific migration version, specified by ``version`` meaning you can't downgrade to a state before the initial migration.

#### Limits
Currently, the generator doesn't detect renames, meaning that if you rename a model in the schema, that table will be dropped and a new one will be created.
Same goes for column, a renamed column will be dropped and a new one will be created, although renaming columns can be manually written in a migration (using ``Alter.renameColumn(oldName, newName)``, but this requires extra work by also renaming it in the schema snapshot file.
