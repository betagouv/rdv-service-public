# frozen_string_literal: true

class AddSearchTermsToPlageOuvertures < ActiveRecord::Migration[6.1]
  def change
    add_column :plage_ouvertures, :search_terms, :text
    add_index :plage_ouvertures, "to_tsvector('simple'::regconfig, COALESCE(plage_ouvertures.search_terms, ''::text))", using: :gin, name: "index_plage_ouvertures_search_terms"
    PlageOuverture.each do |plage_ouverture|
      plage_ouverture.refresh_search_terms
      plage_ouverture.save
    end
  end
end
