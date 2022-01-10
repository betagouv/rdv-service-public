# frozen_string_literal: true

class AddSearchTermsToTeams < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :search_terms, :text
    add_index :teams, "to_tsvector('simple'::regconfig, COALESCE(teams.search_terms, ''::text))", using: :gin, name: "index_teams_search_terms"
  end
end
