class CreateBlogPosts < ActiveRecord::Migration[7.2]
  def change
    create_table :blog_posts do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.string :title, null: false
      t.string :description, null: false
      t.string :categories, array: true, default: []
      t.string :external_url, null: false
      t.datetime :published_at, null: false
    end

    reversible do
      dir.up do
        CronJob::RefreshBlogPostsFromHeadwayJob.perform_now
      end
    end
  end
end
