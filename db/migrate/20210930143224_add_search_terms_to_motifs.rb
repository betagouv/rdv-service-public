# frozen_string_literal: true

class AddSearchTermsToMotifs < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL.squish
      ALTER TABLE motifs
      ADD COLUMN search_terms tsvector GENERATED ALWAYS AS (
        to_tsvector('french', coalesce(name, ''))
      ) STORED;
    SQL
  end

  def down
    remove_column :motifs, :search_terms
  end

end
