group = Group.first || Group.create!

(2 - group.users.count).times do
  group.users.create!
end

group.users.limit(2).each do |user|
  (5 - user.posts.count).times do
    user.posts.create!
  end
end
