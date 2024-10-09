Group.first.users.includes(:posts).map { |user| user.posts.map(&:group) }
