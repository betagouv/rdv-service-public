class UpdateTextSearchTermsForUsers < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      # Supprimer l'ancienne colonne virtuelle
      remove_column :users, :text_search_terms

      # Ajouter la nouvelle colonne virtuelle avec les nouveaux champs
      col_definition = <<~COLUMN
        setweight(to_tsvector('simple', translate(lower(coalesce("users"."last_name", '')), 'àâäéèêëïîôöùûüÿç', 'aaaeeeeiioouuuyc')), 'A') ||
        setweight(to_tsvector('simple', translate(lower(coalesce("users"."first_name", '')), 'àâäéèêëïîôöùûüÿç', 'aaaeeeeiioouuuyc')), 'B') ||
        setweight(to_tsvector('simple', translate(lower(coalesce("users"."birth_name", '')), 'àâäéèêëïîôöùûüÿç', 'aaaeeeeiioouuuyc')), 'C') ||
        setweight(to_tsvector('simple', coalesce("users"."notification_email", '')), 'D') ||
        setweight(to_tsvector('simple', coalesce("users"."account_email", '')), 'D') ||
        setweight(to_tsvector('simple', coalesce("users"."phone_number_formatted", '')), 'D') ||
        setweight(to_tsvector('simple', coalesce("users"."id"::text, '')), 'D')
      COLUMN

      add_column :users, :text_search_terms, :virtual, type: :tsvector, as: col_definition, stored: true
      add_index :users, :text_search_terms, using: :gin, name: "index_users_text_search_terms"
    end
  end

  def down
    safety_assured do
      remove_index :users, :text_search_terms
      remove_column :users, :text_search_terms

      # Rétablir l'ancienne définition si nécessaire
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
end
