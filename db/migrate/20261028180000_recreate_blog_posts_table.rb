class RecreateBlogPostsTable < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      # CronJob::RefreshBlogPostsFromDocsJob sera appelé en fin de job pour re-remplir la table
      execute "TRUNCATE blog_posts" # rubocop:disable Rails/ReversibleMigration

      rename_column :blog_posts, :description, :content_truncated_text
      add_column :blog_posts, :content_html, :text, null: false, default: ""
      change_column_default :blog_posts, :content_html, from: "", to: nil

      remove_column :blog_posts, :id # rubocop:disable Rails/ReversibleMigration
      reversible do |direction|
        direction.up do
          add_column :blog_posts, :id, :uuid, null: false # rubocop:disable Rails/DangerousColumnNames, Rails/NotNullColumn
          execute "ALTER TABLE blog_posts ADD PRIMARY KEY (id)"
        end
        direction.down do
          add_column :blog_posts, :id, :primary_key # rubocop:disable Rails/DangerousColumnNames
        end
      end

      CronJob::RefreshBlogPostsFromDocsJob.perform_later
    end
  end
end
