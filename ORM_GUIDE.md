# Lua ORM Guide (Architecture + Usage)

This document explains what each part of the project does, where it is located, and how to use it.

## 1. Design goals

The ORM is organized to mimic EF Core ideas in Lua:

1. **Metadata layer** defines schema (`Model`, `Field`, `Types`).
2. **Context layer** acts like `DbContext` (connection + model registry + datasets).
3. **Runtime layer** manages entity collections and change state (`DataSet`, `EntityState`).
4. **Query layer** builds filter expressions as AST and compiles them to SQL with parameters.
5. **Migration layer** turns model metadata into `CREATE TABLE` SQL.

Important principle: **`Field` and `Type` are schema metadata only**, not runtime row values.

---

## 2. Project layout

## 2.1 Public entrypoint

| Path | Purpose |
| --- | --- |
| `orm/init.lua` | Main public API export. Exposes `new`, `DbContext`, `Model`, `Field`, `Types`, `Query`, etc. |

`orm/init.lua` supports both:
- `local Orm = require("orm"); local db = Orm.new(config, schema)`
- `local db = require("orm")(config, schema)` (callable module)

## 2.2 Core (context + connection lifecycle)

| Path | Purpose |
| --- | --- |
| `orm/core/context.lua` | `DbContext`: resolves schema, creates datasets, runs schema sync, exposes sets as properties (`db.test`, `db.test2`, ...). |
| `orm/core/connection.lua` | Wraps `pgmoon` connection and query execution with explicit error propagation. |
| `orm/core/unit_of_work.lua` | Placeholder for future `saveChanges` batching logic. |

## 2.3 Metadata (schema DSL)

| Path | Purpose |
| --- | --- |
| `orm/metadata/model.lua` | Table-level schema metadata (`name`, `fields`). |
| `orm/metadata/field.lua` | Column metadata + fluent options (`notNull`, `default`, `primaryKey`, etc.). |
| `orm/metadata/types/init.lua` | Re-export for type registry (currently backed by `orm/types/*`). |
| `orm/types/*.lua` | PostgreSQL-oriented types and default-value formatting. |
| `orm/current-timestamp.lua` | Helper object for `CURRENT_TIMESTAMP[(precision)]` defaults. |

## 2.4 Runtime (entity objects)

| Path | Purpose |
| --- | --- |
| `orm/runtime/dataset.lua` | In-memory entity set with `add/remove/find/all/where/orderBy` and tracking state. |
| `orm/runtime/entity_state.lua` | State constants: `added`, `modified`, `deleted`, `unchanged`. |

## 2.5 Query (AST expression builder)

| Path | Purpose |
| --- | --- |
| `orm/query/ast.lua` | Expression node definitions + fluent expression operations (`eq`, `gt`, `and_`, `or_`, ...). |
| `orm/query/builder.lua` | User helpers: `col(name)`, `val(value)`, `and_`, `or_`. |
| `orm/query/compiler/postgres.lua` | Compiles AST to PostgreSQL SQL with `$1`, `$2`, ... parameter placeholders. |
| `orm/query/init.lua` | Query API facade + `compileWhere(expression)`. |

## 2.6 Migrations

| Path | Purpose |
| --- | --- |
| `orm/migrations/schema_sync.lua` | Builds `CREATE TABLE IF NOT EXISTS ...` statements from model metadata; optionally executes them. |

---

## 3. Main flow

1. User creates a context (`Orm.new(config, schemaProvider)`).
2. `DbContext` resolves schema (table or function returning model list).
3. `DbContext` runs `SchemaSync.apply(...)`:
   - Generates DDL statements always.
   - Executes only when `config.autoMigrate == true`.
4. `DbContext` creates a `DataSet` per model and exposes it by model name.
5. Query filters are built as AST and compiled separately to parameterized SQL.

---

## 4. Example: defining models

From `examples/ex1/models/Test.lua` style:

```lua
local Model = require("orm.metadata.model")
local Field = require("orm.metadata.field")
local Types = require("orm.metadata.types")
local CurrentTimestamp = require("orm.current-timestamp")

local Test = Model("test", {
  Field("id", Types.Int):primaryKey(),
  Field("text", Types.Text):default("Default text"):notNull(),
  Field("created_at", Types.Timestamp):default(CurrentTimestamp(3)):notNull(),
})

return Test
```

Key point: this declares schema only.

---

## 5. Example: creating context (DbContext pattern)

From `examples/ex1/context.lua`:

```lua
local Orm = require("orm")
local lfs = require("lfs")

local config = {
  host = "127.0.0.1",
  port = 5432,
  database = "medix",
  user = "medix",
  password = "medix",
  autoMigrate = false, -- set true to execute generated CREATE TABLE statements
}

local function fetchSchema()
  local models = {}
  for file in lfs.dir("examples/ex1/models") do
    if file:match("%.lua$") then
      table.insert(models, require("models." .. file:sub(1, -5)))
    end
  end
  return models
end

local db = Orm.new(config, fetchSchema)
```

Accessing sets:

```lua
local tests = db.test
local tests2 = db.test2
```

---

## 6. Example: DataSet runtime behavior

`DataSet` currently works as tracked in-memory collection:

```lua
local entity = { id = 1, text = "hello" }
db.test:add(entity)
print(db.test:stateOf(entity)) -- added

entity.text = "changed"
db.test:markModified(entity)
print(db.test:stateOf(entity)) -- modified (unless still added)

local same = db.test:find(1)
local all = db.test:all()
local filtered = db.test:where(function(e) return e.id > 0 end)
local sorted = db.test:orderBy("id", "desc")
```

---

## 7. Example: AST filtering and SQL compilation

```lua
local Orm = require("orm")

local expr = Orm.Query
  .col("test.id")
  :gt(0)
  :and_(Orm.Query.col("test.text"):ne(nil))

local whereSql, params = Orm.Query.compileWhere(expr)
print(whereSql)   -- WHERE ("test"."id" > $1 AND "test"."text" IS NOT NULL)
print(params[1])  -- 0
```

Notes:
- Identifiers are quoted for PostgreSQL (`"test"."id"`).
- Values are parameterized (`$1`, `$2`, ...).
- `= nil` and `<> nil` compile to `IS NULL` / `IS NOT NULL`.

---

## 8. Current state vs next steps

Implemented now:
- Architecture split into clear modules.
- DbContext-like user module pattern.
- In-memory dataset with entity state tracking.
- AST expression builder + Postgres compiler.
- Schema sync generation and optional execution.
- Example project using context and query AST.

Planned next (for course/project growth):
1. Integrate `DataSet` + `UnitOfWork` with actual SQL `INSERT/UPDATE/DELETE` in `saveChanges`.
2. Expand migrations from create-if-missing to column diffs and alter support.
3. Add query execution API (`db.test:whereAst(expr):toList()` style).
4. Add automated tests for AST compiler, type defaults, and schema DDL generation.
