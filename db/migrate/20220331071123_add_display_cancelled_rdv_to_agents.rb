# frozen_string_literal: true

class AddDisplayCancelledRdvToAgents < ActiveRecord::Migration[6.1]
  def change
    add_column :agents, :display_cancelled_rdv, :boolean, default: true
  end
end
