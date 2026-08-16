---@diagnostic disable: undefined-global, undefined-field

package.path = "./?.lua;./?/init.lua;" .. package.path

local Model = require("orm.model")
local Types = require("orm.model.types")
local Constraint = require("orm.model.constraint")
local Relation = require("orm.model.relation")
local Context = require("orm.context")
local EntityEntry = require("orm.change-tracking.entity-entry")

describe("inverse relations", function()
    local User
    local Profile
    local Post
    local context
    local queryResult

    before_each(function()
        User = Model("users", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "name", Types.Text },
            { "profile", Relation.hasOne("profiles", "user_id") },
            { "posts", Relation.hasMany("posts", "user_id") },
        })

        Profile = Model("profiles", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "bio", Types.Text },
            { "user", Relation.belongsTo("users", "id"), Constraint.Unique },
        })

        Post = Model("posts", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "title", Types.Text },
            { "user", Relation.belongsTo("users", "id") },
        })

        context = Context.new({}, { User, Profile, Post })
        context.getCompiler = function()
            return {
                compileSelect = function()
                    return "SELECT", {}
                end,
                compileSelectFirst = function()
                    return "SELECT FIRST", {}
                end,
            }
        end
        context.query_array = function()
            return queryResult
        end
    end)

    it("resolves inverse join metadata without generating owner fields", function()
        local profile = User.relations.profile
        local posts = User.relations.posts

        assert.equals("id", profile.sourceColumn)
        assert.equals("user_id", profile.targetColumn)
        assert.equals(Profile, profile.targetModel)
        assert.equals("id", posts.sourceColumn)
        assert.equals("user_id", posts.targetColumn)
        assert.equals(Post, posts.targetModel)
        assert.is_nil(User.fieldsByName.profile)
        assert.is_nil(User.fieldsByName.posts)
    end)

    it("materializes hasOne and deduplicated hasMany results", function()
        queryResult = {
            { 1, "User", 10, "Bio", 1, 100, "First", 1 },
            { 1, "User", 10, "Bio", 1, 101, "Second", 1 },
            fields = {
                "id", "name",
                "id", "bio", "user_id",
                "id", "title", "user_id",
            },
        }

        local users = context.data.users:include(function(user)
            return user.profile, user.posts
        end):all()

        assert.equals(1, #users)
        assert.equals(10, users[1].profile.id)
        assert.equals(2, #users[1].posts)
        assert.equals(100, users[1].posts[1].id)
        assert.equals(101, users[1].posts[2].id)
    end)

    it("deduplicates multiple hasMany collections across Cartesian rows", function()
        local Root = Model("multi_users", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "posts", Relation.hasMany("multi_posts", "user_id") },
            { "comments", Relation.hasMany("multi_comments", "user_id") },
        })
        local MultiPost = Model("multi_posts", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "user", Relation.belongsTo("multi_users", "id") },
        })
        local Comment = Model("multi_comments", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "user", Relation.belongsTo("multi_users", "id") },
        })
        local multiContext = Context.new({}, { Root, MultiPost, Comment })
        local result = {
            { 1, 10, 1, 20, 1 },
            { 1, 10, 1, 21, 1 },
            { 1, 11, 1, 20, 1 },
            { 1, 11, 1, 21, 1 },
            fields = { "id", "id", "user_id", "id", "user_id" },
        }
        multiContext.getCompiler = function()
            return { compileSelect = function() return "SELECT", {} end }
        end
        multiContext.query_array = function()
            return result
        end

        local root = multiContext.data.multi_users:include(function(entity)
            return entity.posts, entity.comments
        end):all()[1]

        assert.equals(2, #root.posts)
        assert.equals(2, #root.comments)
    end)

    it("returns empty hasMany collections for unmatched left joins", function()
        local null = {}
        context.connection.client.NULL = null
        queryResult = {
            { 1, "User", null, null, null },
            fields = { "id", "name", "id", "title", "user_id" },
        }

        local user = context.data.users:include(function(entity)
            return entity.posts
        end):first()

        assert.is_table(user.posts)
        assert.equals(0, #user.posts)
    end)

    it("materializes every hasMany row returned by first", function()
        queryResult = {
            { 1, "User", 100, "First", 1 },
            { 1, "User", 101, "Second", 1 },
            fields = { "id", "name", "id", "title", "user_id" },
        }

        local user = context.data.users:include(function(entity)
            return entity.posts
        end):first()

        assert.equals(2, #user.posts)
    end)

    it("keeps hasMany collection assignment read-only", function()
        local user = context:_materialize(User, { id = 1, name = "User" })
        local post = context:_materialize(Post, { id = 100, title = "Post", user_id = 1 })
        User._setLoadedRelation(user, "posts", { post })

        assert.has_error(function()
            user.posts = {}
        end, "HAS_MANY relation 'users.posts' is read-only; update the target BELONGS_TO relation instead")

        assert.equals(1, #user.posts)
        assert.equals(1, post.user_id)
        assert.equals(EntityEntry.State.UNCHANGED, context.changeTracker:getEntry(post).state)
    end)

    it("tracks both targets when replacing a hasOne relation", function()
        local user = context:_materialize(User, { id = 1, name = "User" })
        local previous = context:_materialize(Profile, { id = 10, bio = "Old", user_id = 1 })
        local replacement = context:_materialize(Profile, { id = 11, bio = "New" })
        User._setLoadedRelation(user, "profile", previous)

        user.profile = replacement

        assert.equals(replacement, user.profile)
        assert.is_nil(previous.user_id)
        assert.equals(1, replacement.user_id)
        assert.equals(EntityEntry.State.MODIFIED, context.changeTracker:getEntry(previous).state)
        assert.equals(EntityEntry.State.MODIFIED, context.changeTracker:getEntry(replacement).state)
    end)

    it("requires persisted hasOne relations to be loaded before replacement", function()
        local user = context:_materialize(User, { id = 1, name = "User" })
        local profile = context:_materialize(Profile, { id = 10, bio = "Profile" })

        assert.has_error(function()
            user.profile = profile
        end, "Relation 'users.profile' must be loaded before it can be replaced")
    end)

    it("fixes up loaded inverse collections when belongsTo is assigned", function()
        local user = context:_materialize(User, { id = 1, name = "User" })
        local post = context:_materialize(Post, { id = 100, title = "Post" })
        User._setLoadedRelation(user, "posts", {})

        post.user = user

        assert.equals(1, post.user_id)
        assert.equals(user, post.user)
        assert.equals(1, #user.posts)
        assert.equals(post, user.posts[1])
        assert.is_true(context.changeTracker:getEntry(post).changedFields.user_id)
    end)

    it("rejects hasOne targets whose foreign key is not unique", function()
        local InvalidUser = Model("invalid_users", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "profile", Relation.hasOne("invalid_profiles", "user_id") },
        })
        local InvalidProfile = Model("invalid_profiles", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "user_id", Types.Int, Constraint.ForeignKey("invalid_users", "id") },
        })

        assert.has_error(function()
            Context.new({}, { InvalidUser, InvalidProfile })
        end)
    end)

    it("invalidates a loaded hasMany collection when its source key changes", function()
        local user = context:_materialize(User, { id = 1, name = "User" })
        local post = context:_materialize(Post, { id = 100, title = "Post", user_id = 1 })
        User._setLoadedRelation(user, "posts", { post })

        user.id = 2

        assert.is_nil(user.posts)
        assert.equals(1, post.user_id)
        assert.equals(EntityEntry.State.UNCHANGED, context.changeTracker:getEntry(post).state)
    end)

    it("does not hydrate a stale identity-mapped child into a collection", function()
        local post = context:_materialize(Post, { id = 100, title = "Post", user_id = 1 })
        post.user_id = 2
        queryResult = {
            { 1, "User", 100, "Post", 1 },
            fields = { "id", "name", "id", "title", "user_id" },
        }

        local user = context.data.users:include(function(entity)
            return entity.posts
        end):first()

        assert.equals(0, #user.posts)
        assert.equals(2, post.user_id)
    end)

    it("fixes up owners by identity when moving a target between equal keys", function()
        local firstOwner = User.new({ id = 1, name = "First" })
        local secondOwner = User.new({ id = 1, name = "Second" })
        local post = Post.new({ id = 100, title = "Post", user_id = 1 })
        User._setLoadedRelation(firstOwner, "posts", { post })
        User._setLoadedRelation(secondOwner, "posts", {})
        Post._setLoadedRelation(post, "user", firstOwner)

        post.user = secondOwner

        assert.equals(0, #firstOwner.posts)
        assert.equals(1, #secondOwner.posts)
        assert.equals(secondOwner, post.user)
    end)

    it("requires hasMany owners to have a primary key", function()
        local KeylessOwner = Model("keyless_owners", {
            { "code", Types.Int, Constraint.Unique },
            { "items", Relation.hasMany("keyless_items", "owner_code", { localColumn = "code" }) },
        })
        local Item = Model("keyless_items", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "owner_code", Types.Int, Constraint.ForeignKey("keyless_owners", "code") },
        })

        assert.has_error(function()
            Context.new({}, { KeylessOwner, Item })
        end)
    end)

    it("rejects inverse targets that are not matching foreign keys", function()
        local InvalidUser = Model("invalid_users", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "posts", Relation.hasMany("invalid_posts", "user_id") },
        })
        local InvalidPost = Model("invalid_posts", {
            { "id", Types.Int, Constraint.PrimaryKey },
            { "user_id", Types.Int },
        })

        assert.has_error(function()
            Context.new({}, { InvalidUser, InvalidPost })
        end)
    end)
end)
