class DropNotificationEmailAndRecreateTextSearchTerms < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      col_definition = <<~COLUMN
        setweight(to_tsvector('simple', translate(lower(coalesce("users"."last_name", '')),  'àâäéèêëïîôöùûüÿç', 'aaaeeeeiioouuuyc')), 'A') ||
        setweight(to_tsvector('simple', translate(lower(coalesce("users"."first_name", '')), 'àâäéèêëïîôöùûüÿç', 'aaaeeeeiioouuuyc')), 'B') ||
        setweight(to_tsvector('simple', translate(lower(coalesce("users"."birth_name", '')), 'àâäéèêëïîôöùûüÿç', 'aaaeeeeiioouuuyc')), 'C') ||
        setweight(to_tsvector('simple', split_part(coalesce("users"."email", ''), '@', 1)), 'D')
      COLUMN

      add_column :users, :text_search_terms, :virtual, type: :tsvector, as: col_definition, stored: true
    end
  end

  def down
    remove_column :users, :text_search_terms
  end
end
