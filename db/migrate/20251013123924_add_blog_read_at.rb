class AddBlogReadAt < ActiveRecord::Migration[7.1]
  def change
    add_column :agents, :blog_read_at, :datetime
  end
end
