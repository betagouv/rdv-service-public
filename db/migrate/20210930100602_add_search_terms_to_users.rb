# frozen_string_literal: true

class AddSearchTermsToUsers < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL.squish
      ALTER TABLE users
      ADD COLUMN search_terms tsvector GENERATED ALWAYS AS (
        to_tsvector('french', coalesce(first_name, '')) ||
        to_tsvector('french', coalesce(birth_name,'')) ||
        to_tsvector('french', coalesce(last_name, '')) ||
        to_tsvector('french', coalesce(email, '')) ||
        to_tsvector('french', coalesce(phone_number_formatted, '')) ||
        to_tsvector('french', coalesce(phone_number, ''))
      ) STORED;
    SQL
  end

  def down
    remove_column :users, :search_terms
  end
end
