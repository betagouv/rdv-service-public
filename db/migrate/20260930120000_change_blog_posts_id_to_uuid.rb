class ChangeBlogPostsIdToUuid < ActiveRecord::Migration[8.0]
  # La table contient une dizaine de lignes, recréées régulièrement par RefreshBlogPostsFromDocsJob :
  # pas de souci de blocage d'écriture.
  def up
    safety_assured do
      # On réutilise l'UUID du document Docs, présent à la fin de external_url
      add_column :blog_posts, :uuid, :uuid
      execute "UPDATE blog_posts SET uuid = substring(external_url from '[^/]+$')::uuid"

      remove_column :blog_posts, :id
      rename_column :blog_posts, :uuid, :id # rubocop:disable Rails/DangerousColumnNames
      change_column_null :blog_posts, :id, false
      execute "ALTER TABLE blog_posts ADD PRIMARY KEY (id)"
    end
  end

  def down
    safety_assured do
      execute "TRUNCATE blog_posts"
      remove_column :blog_posts, :id
      add_column :blog_posts, :id, :primary_key # rubocop:disable Rails/DangerousColumnNames
    end
  end
end
