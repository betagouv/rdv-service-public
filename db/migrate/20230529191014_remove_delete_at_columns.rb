# frozen_string_literal: true

class RemoveDeleteAtColumns < ActiveRecord::Migration[7.0]
  def change
    reversible do |direction|
      direction.up do
        Rdv.where.not(deleted_at: nil).destroy_all
        User.where.not(deleted_at: nil).destroy_all
        Agent.where.not(deleted_at: nil).destroy_all
      end
    end

    remove_column :rdvs, :deleted_at, :datetime
    remove_column :users, :deleted_at, :datetime
    remove_column :agents, :deleted_at, :datetime

    remove_column :users, :email_original, :string
    remove_column :agents, :email_original, :string

    rename_column :motifs, :deleted_at, :archived_at
  end
end
