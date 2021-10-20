# frozen_string_literal: true

class AddSearchTermsToUsersMotifsAndAgents < ActiveRecord::Migration[6.0]
  def change
    add_column :agents, :search_terms, :text
    add_index :agents, "to_tsvector('simple'::regconfig, COALESCE(agents.search_terms, ''::text))", using: :gin, name: "index_agents_search_terms"
    add_column :users, :search_terms, :text
    add_index :users, "to_tsvector('simple'::regconfig, COALESCE(users.search_terms, ''::text))", using: :gin, name: "index_users_search_terms"
    add_index :motifs, "to_tsvector('simple'::regconfig, COALESCE(motifs.name, ''::text))", using: :gin, name: "index_motifs_name_vector"

    User.in_batches(of: 300).each_with_index do |user, batch_index|
      Rails.logger.info "update users to init search terms for batch ##{batch_index}"
      user.map { |u| u.update_column(:search_terms, u.combined_search_terms) }
    end

    Agent.in_batches(of: 300).each_with_index do |agent, batch_index|
      Rails.logger.info "update agents to init search terms for batch ##{batch_index}"
      agent.map { |a| a.update_column(:search_terms, a.combined_search_terms) }
    end
  end
end
