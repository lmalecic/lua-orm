# Lua ORM architecture plan

## Progress status
- All planned items in this phase are complete:
  - `orm-structure-boundaries` ✅
  - `dbcontext-user-module` ✅
  - `dataset-runtime-entities` ✅
  - `ast-query-builder` ✅
  - `schema-migrations-sync` ✅
  - `type-defaults-hardening` ✅
  - `example-refactor` ✅

## Problem and approach
Build an object-oriented Lua ORM with EF Core-like ergonomics, while keeping schema metadata, query building, and runtime entity state clearly separated.  
The core direction is:
1. Keep `Field` and `Type` as **metadata-only** schema DSL (table/column definition), not runtime value containers.
2. Introduce a `DbContext`-style user module that owns connection config, model registration, and table access (`context.Users`, `context.Posts`, ...).
3. Build query/filtering with an AST expression system and SQL compiler (Postgres dialect first), so callers avoid raw SQL strings.
4. Implement `DataSet` as repository/query root (CRUD + query composition) and add unit-of-work style `saveChanges`.

## Todos
- **orm-structure-boundaries**: Define and enforce module boundaries between core ORM internals, schema metadata DSL, query AST/compiler, and user-facing context layer.
- **dbcontext-user-module**: Add a dedicated `DbContext` abstraction and user-facing context module pattern (instead of putting app models/config directly in ORM core).
- **dataset-runtime-entities**: Implement `DataSet` around runtime entity instances (plain Lua tables + tracked state), with APIs like `add/remove/find/all/where/orderBy`.
- **ast-query-builder**: Design expression node types (comparison, logical, member access, constants), fluent builder API, and SQL generation pipeline for safe filtering.
- **schema-migrations-sync**: Implement schema synchronization flow (`_updateSchema`) from model metadata to SQL DDL, including constraints/defaults/identity handling.
- **type-defaults-hardening**: Fix and harden type/default formatting edge-cases (`Timestamp/TimestampTz` current timestamp handling and table-type checks).
- **example-refactor**: Update `examples/ex1` to the new context-based usage and AST filters to demonstrate intended public API.

## Notes and considerations
- `Field` should remain immutable after model finalization (or cloned per model build) to avoid accidental cross-model mutation from fluent calls.
- Runtime entity values should live in entity objects only; metadata (`Field`) should never carry row data.
- For EF-like behavior, keep change tracking explicit and deterministic: entity states (`added`, `modified`, `deleted`, `unchanged`) managed by context/unit-of-work.
- Query AST should compile to parameterized SQL (`$1`, `$2`, ...), not interpolated literals.
- Keep Postgres-specific pieces (types, DDL quirks) in dialect/compiler modules so other backends can be added later.
- Suggested package layout:
  - `orm/core/` (`context.lua`, `connection.lua`, `unit_of_work.lua`)
  - `orm/metadata/` (`model.lua`, `field.lua`, `types/...`)
  - `orm/query/` (`ast.lua`, `builder.lua`, `compiler/postgres.lua`)
  - `orm/runtime/` (`dataset.lua`, `entity_state.lua`)
  - `orm/migrations/` (`schema_sync.lua`)
  - `orm/init.lua` (public exports only)
