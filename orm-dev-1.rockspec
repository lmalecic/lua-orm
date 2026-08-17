package = "orm"
version = "dev-1"

source = {
	url = "local",
}

dependencies = {
	"lua >= 5.1",
	"pgmoon 1.18.0-1",
	"luasocket 3.1.0-1",
	"luabitop 1.0.3-1",
	"luaossl 20250929-0",
	"luafilesystem 1.9.0-1",
}

build = {
	type = "builtin",
	modules = {
		["orm.connection"] = "orm/connection.lua",
		["orm.context"] = "orm/context.lua",

		["orm.model"] = "orm/model/init.lua",
		["orm.model.types"] = "orm/model/types/init.lua",
		["orm.model.types.type"] = "orm/model/types/type.lua",
		["orm.model.types.char"] = "orm/model/types/char.lua",
		["orm.model.types.decimal"] = "orm/model/types/decimal.lua",
		["orm.model.types.float"] = "orm/model/types/float.lua",
		["orm.model.types.int"] = "orm/model/types/int.lua",
		["orm.model.types.text"] = "orm/model/types/text.lua",
		["orm.model.types.timestamp"] = "orm/model/types/timestamp.lua",
		["orm.model.types.timestamptz"] = "orm/model/types/timestamptz.lua",
		["orm.model.types.varchar"] = "orm/model/types/varchar.lua",
		["orm.model.expressions.current-timestamp"] = "orm/model/expressions/current-timestamp.lua",
		["orm.model.constraint"] = "orm/model/constraint.lua",
		["orm.model.field"] = "orm/model/field.lua",
		["orm.model.model-relation"] = "orm/model/model-relation.lua",
		["orm.model.relation"] = "orm/model/relation.lua",

		["orm.query"] = "orm/query/init.lua",
		["orm.query.compiler.pg"] = "orm/query/compiler/pg.lua",
		["orm.query.node.comparison"] = "orm/query/node/comparison.lua",
		["orm.query.node.constant"] = "orm/query/node/constant.lua",
		["orm.query.node.logical"] = "orm/query/node/logical.lua",
		["orm.query.node.order"] = "orm/query/node/order.lua",
		["orm.query.node.unary"] = "orm/query/node/unary.lua",
		["orm.query.proxy.entity"] = "orm/query/proxy/entity.lua",
		["orm.query.proxy.entity-relation"] = "orm/query/proxy/entity-relation.lua",
		["orm.query.proxy.field"] = "orm/query/proxy/field.lua",
		["orm.query.proxy.order-field"] = "orm/query/proxy/order-field.lua",
		["orm.query.proxy.relation-field"] = "orm/query/proxy/relation-field.lua",
		["orm.query.dataset"] = "orm/query/dataset.lua",
		["orm.query.specification"] = "orm/query/specification.lua",

		["orm.change-tracking.entity-entry"] = "orm/change-tracking/entity-entry.lua",
		["orm.change-tracking.tracker"] = "orm/change-tracking/tracker.lua",
		["orm.change-tracking.value"] = "orm/change-tracking/value.lua",

		["orm.helpers.value"] = "orm/helpers/value.lua",

		["orm.migrations"] = "orm/migrations/init.lua",
		["orm.migrations.alter"] = "orm/migrations/alter.lua",
		["orm.migrations.generator"] = "orm/migrations/generator.lua",
		["orm.migrations.migration-builder"] = "orm/migrations/migration-builder.lua",
	}
}
