class AddIndexToForumers < ActiveRecord::Migration
  def change
    add_index :forumers, :forum_id
    add_index :forumers, :group_id
  end
end
