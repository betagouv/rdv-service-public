# frozen_string_literal: true

class AddCnfsSecondaryEmailToAgents < ActiveRecord::Migration[7.0]
  def change
    add_column :agents, :cnfs_secondary_email, :string
  end
end
