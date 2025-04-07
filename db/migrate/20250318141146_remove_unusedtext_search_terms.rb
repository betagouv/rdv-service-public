class RemoveUnusedtextSearchTerms < ActiveRecord::Migration[7.1]
  def up
    safety_assured { remove_column :users, :text_search_terms }
  end

  def down
    col_definition = <<~COLUMN
      setweight(to_tsvector('simple', translate(lower(coalesce("users"."last_name", '')), 'àâäéèêëïîôöùûüÿç', 'aaaeeeeiioouuuyc')), 'A') ||
      setweight(to_tsvector('simple', translate(lower(coalesce("users"."first_name", '')), 'àâäéèêëïîôöùûüÿç', 'aaaeeeeiioouuuyc')), 'B') ||
      setweight(to_tsvector('simple', translate(lower(coalesce("users"."birth_name", '')), 'àâäéèêëïîôöùûüÿç', 'aaaeeeeiioouuuyc')), 'C') ||
      setweight(to_tsvector('simple', coalesce("users"."email", '')), 'D') ||
      setweight(to_tsvector('simple', coalesce("users"."phone_number_formatted", '')), 'D') ||
      setweight(to_tsvector('simple', coalesce("users"."id"::text, '')), 'D')
    COLUMN

    add_column :users, :text_search_terms, :virtual, type: :tsvector, as: col_definition, stored: true
    add_index :users, :text_search_terms, using: :gin, name: "index_users_text_search_terms"
  end
end
