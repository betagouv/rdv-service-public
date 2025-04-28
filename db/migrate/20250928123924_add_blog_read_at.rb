class AddBlogReadAt < ActiveRecord::Migration[7.1]
  def change
    add_column :agents, :blog_read_at, :datetime, null: false, default: Time.zone.parse("2025-09-28 20:00")
  end
end
