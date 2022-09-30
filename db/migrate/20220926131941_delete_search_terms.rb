# frozen_string_literal: true

class DeleteSearchTerms < ActiveRecord::Migration[6.1]
  def up
    remove_column :agents, :search_terms
    remove_column :plage_ouvertures, :search_terms
    remove_column :teams, :search_terms
    remove_column :users, :search_terms
  end

  def down
    add_column :agents, :search_terms, :text
    add_column :plage_ouvertures, :search_terms, :text
    add_column :teams, :search_terms, :text
    add_column :users, :search_terms, :text

    add_index :agents, "to_tsvector('simple'::regconfig, COALESCE(users.search_terms, ''::text))", using: :gin, name: "index_agents_search_terms"
    add_index :plage_ouvertures, "to_tsvector('simple'::regconfig, COALESCE(plage_ouvertures.search_terms, ''::text))", using: :gin, name: "index_plage_ouvertures_search_terms"
    add_index :teams, "to_tsvector('simple'::regconfig, COALESCE(teams.search_terms, ''::text))", using: :gin, name: "index_teams_search_terms"
    add_index :users, "to_tsvector('simple'::regconfig, COALESCE(users.search_terms, ''::text))", using: :gin, name: "index_users_search_terms"
  end
end
