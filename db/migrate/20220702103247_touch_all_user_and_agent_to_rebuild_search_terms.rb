# frozen_string_literal: true

class TouchAllUserAndAgentToRebuildSearchTerms < ActiveRecord::Migration[6.1]
  def change
    User.find_each do |user|
      user.refresh_search_terms
      user.save
    end
    Agent.find_each do |agent|
      agent.refresh_search_terms
      agent.save
    end
  end
end
