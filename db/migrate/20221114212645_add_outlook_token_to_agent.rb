# frozen_string_literal: true

class AddOutlookTokenToAgent < ActiveRecord::Migration[6.1]
  def change
    add_column :agents, :microsoft_graph_token, :text
    add_column :agents, :refresh_microsoft_graph_token, :text
  end
end
