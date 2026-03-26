class DropNotificationEmailAndRecreateTextSearchTerms < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      remove_index :users, name: "index_users_text_search_terms_with_notification_email"
      remove_column :users, :text_search_terms_with_notification_email, :virtual

      remove_index :users, name: "index_users_on_notification_email"
      remove_column :users, :notification_email, :string

      col_definition = <<~COLUMN
        setweight(to_tsvector('simple', translate(lower(coalesce("users"."last_name", '')), 'àâäéèêëïîôöùûüÿç', 'aaaeeeeiioouuuyc')), 'A') ||
        setweight(to_tsvector('simple', translate(lower(coalesce("users"."first_name", '')), 'àâäéèêëïîôöùûüÿç', 'aaaeeeeiioouuuyc')), 'B') ||
        setweight(to_tsvector('simple', translate(lower(coalesce("users"."birth_name", '')), 'àâäéèêëïîôöùûüÿç', 'aaaeeeeiioouuuyc')), 'C') ||
        setweight(to_tsvector('simple', coalesce("users"."email", '')), 'D') ||
        setweight(to_tsvector('simple', coalesce("users"."phone_number_formatted", '')), 'D') ||
        setweight(to_tsvector('simple', coalesce("users"."id"::text, '')), 'D')
      COLUMN

      add_column :users, :text_search_terms, :virtual, type: :tsvector, as: col_definition, stored: true
    end
  end
end
