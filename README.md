Given the following rails project:

```ruby
# db/schema.rb

ActiveRecord::Schema[7.1].define(version: 2024_10_09_192237) do
  create_table "groups", force: :cascade do |t|
  end

  create_table "posts", force: :cascade do |t|
    t.integer "user_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "group_id"
    t.index ["group_id"], name: "index_users_on_group_id"
  end
end
  
# app/models/group.rb
class Group < ApplicationRecord
  has_many :users
  has_many :posts, through: :users
end

# app/models/user.rb 
class User < ApplicationRecord
  belongs_to :group
  has_many :posts
end

# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user

  has_one :group, through: :user
end
```

We seed the database with 1 group that has 2 users, each with 5 posts.

This query results in N+1 queries for the group:

```
irb(main):001> Group.first.users.includes(:posts).map { |user| user.posts.map(&:group) }
  Group Load (0.2ms)  SELECT "groups".* FROM "groups" ORDER BY "groups"."id" ASC LIMIT ?  [["LIMIT", 1]]
  User Load (0.2ms)  SELECT "users".* FROM "users" WHERE "users"."group_id" = ?  [["group_id", 1]]
  Post Load (0.2ms)  SELECT "posts".* FROM "posts" WHERE "posts"."user_id" IN (?, ?)  [["user_id", 11], ["user_id", 12]]
  Group Load (0.3ms)  SELECT "groups".* FROM "groups" INNER JOIN "users" ON "groups"."id" = "users"."group_id" WHERE "users"."id" = ? LIMIT ?  [["id", 11], ["LIMIT", 1]]
  Group Load (0.1ms)  SELECT "groups".* FROM "groups" INNER JOIN "users" ON "groups"."id" = "users"."group_id" WHERE "users"."id" = ? LIMIT ?  [["id", 11], ["LIMIT", 1]]
  Group Load (0.1ms)  SELECT "groups".* FROM "groups" INNER JOIN "users" ON "groups"."id" = "users"."group_id" WHERE "users"."id" = ? LIMIT ?  [["id", 11], ["LIMIT", 1]]
  Group Load (0.1ms)  SELECT "groups".* FROM "groups" INNER JOIN "users" ON "groups"."id" = "users"."group_id" WHERE "users"."id" = ? LIMIT ?  [["id", 11], ["LIMIT", 1]]
  Group Load (0.0ms)  SELECT "groups".* FROM "groups" INNER JOIN "users" ON "groups"."id" = "users"."group_id" WHERE "users"."id" = ? LIMIT ?  [["id", 11], ["LIMIT", 1]]
  Group Load (0.0ms)  SELECT "groups".* FROM "groups" INNER JOIN "users" ON "groups"."id" = "users"."group_id" WHERE "users"."id" = ? LIMIT ?  [["id", 12], ["LIMIT", 1]]
  Group Load (0.0ms)  SELECT "groups".* FROM "groups" INNER JOIN "users" ON "groups"."id" = "users"."group_id" WHERE "users"."id" = ? LIMIT ?  [["id", 12], ["LIMIT", 1]]
  Group Load (0.0ms)  SELECT "groups".* FROM "groups" INNER JOIN "users" ON "groups"."id" = "users"."group_id" WHERE "users"."id" = ? LIMIT ?  [["id", 12], ["LIMIT", 1]]
  Group Load (0.0ms)  SELECT "groups".* FROM "groups" INNER JOIN "users" ON "groups"."id" = "users"."group_id" WHERE "users"."id" = ? LIMIT ?  [["id", 12], ["LIMIT", 1]]
  Group Load (0.0ms)  SELECT "groups".* FROM "groups" INNER JOIN "users" ON "groups"."id" = "users"."group_id" WHERE "users"."id" = ? LIMIT ?  [["id", 12], ["LIMIT", 1]]
=>
[[#<Group:0x00007ff1903c8988 id: 1>, #<Group:0x00007ff1903c7088 id: 1>, #<Group:0x00007ff1903c5f08 id: 1>, #<Group:0x00007ff1903c4c48 id: 1>, #<Group:0x00007ff1903c3848 id: 1>],
 [#<Group:0x00007ff1903c2e48 id: 1>, #<Group:0x00007ff1903c21c8 id: 1>, #<Group:0x00007ff1903c17c8 id: 1>, #<Group:0x00007ff1903c0b48 id: 1>, #<Group:0x00007ff190a4fdd8 id: 1>]]
```

Whereas if we change the definition of `Post` to have a simple method for
`group` instead of the `has_one`, as follows:

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user

  def group
    user.group
  end
end
```

Then the query proceeds as desired:

```
irb(main):001> Group.first.users.includes(:posts).map { |user| user.posts.map(&:group) }
  Group Load (0.1ms)  SELECT "groups".* FROM "groups" ORDER BY "groups"."id" ASC LIMIT ?  [["LIMIT", 1]]
  User Load (0.1ms)  SELECT "users".* FROM "users" WHERE "users"."group_id" = ?  [["group_id", 1]]
  Post Load (0.2ms)  SELECT "posts".* FROM "posts" WHERE "posts"."user_id" IN (?, ?)  [["user_id", 11], ["user_id", 12]]
=>
[[#<Group:0x00007f16521f94f0 id: 1>, #<Group:0x00007f16521f94f0 id: 1>, #<Group:0x00007f16521f94f0 id: 1>, #<Group:0x00007f16521f94f0 id: 1>, #<Group:0x00007f16521f94f0 id: 1>],
 [#<Group:0x00007f16521f94f0 id: 1>, #<Group:0x00007f16521f94f0 id: 1>, #<Group:0x00007f16521f94f0 id: 1>, #<Group:0x00007f16521f94f0 id: 1>, #<Group:0x00007f16521f94f0 id: 1>]]
```
