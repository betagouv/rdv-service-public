class AddContentHtmlToBlogPosts < ActiveRecord::Migration[8.0]
  # La table contient une dizaine de lignes, recréées régulièrement par RefreshBlogPostsFromDocsJob :
  # pas de souci de blocage d'écriture. Le contenu HTML des posts existants sera rempli au prochain passage du job.
  def change
    safety_assured do
      rename_column :blog_posts, :description, :content_truncated_text
      add_column :blog_posts, :content_html, :text, null: false, default: ""
      change_column_default :blog_posts, :content_html, from: "", to: nil
    end
  end
end
