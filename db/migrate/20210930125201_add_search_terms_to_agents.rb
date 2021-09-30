# frozen_string_literal: true

class AddSearchTermsToAgents < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL.squish
      ALTER TABLE agents
      ADD COLUMN search_terms tsvector GENERATED ALWAYS AS (
        to_tsvector('french', coalesce(first_name, '')) ||
        to_tsvector('french', coalesce(last_name, '')) ||
        to_tsvector('french', coalesce(email, ''))
      ) STORED;
    SQL
  end

  def down
    remove_column :agents, :search_terms
  end
end
