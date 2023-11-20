class ReplaceAccentsInDb < ActiveRecord::Migration[7.0]
  def up
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

    remove_column :users, :searchable
    remove_column :users, :unaccented_last_name
    remove_column :users, :unaccented_first_name
    remove_column :users, :unaccented_birth_name
  end

  def down
    remove_column :users, :text_search_terms

    col_definition = <<~COLUMN
      setweight(to_tsvector('simple', coalesce("users"."unaccented_last_name" :: text, '')), 'A') ||
      setweight(to_tsvector('simple', coalesce("users"."unaccented_first_name" :: text, '')), 'B') ||
      setweight(to_tsvector('simple', coalesce("users"."unaccented_birth_name" :: text, '')), 'C') ||
      setweight(to_tsvector('simple', coalesce("users"."email" :: text, '')), 'D') ||
      setweight(to_tsvector('simple', coalesce("users"."phone_number_formatted" :: text, '')), 'D') ||
      setweight(to_tsvector('simple', coalesce("users"."id" :: text, '')), 'D')
    COLUMN

    add_column :users, :searchable, :virtual, type: :tsvector, as: col_definition, stored: true
    add_index :users, :searchable, using: :gin, name: "index_users_searchable"

    add_column :users, :unaccented_last_name, :text
    add_column :users, :unaccented_first_name, :text
    add_column :users, :unaccented_birth_name, :text
  end
end
