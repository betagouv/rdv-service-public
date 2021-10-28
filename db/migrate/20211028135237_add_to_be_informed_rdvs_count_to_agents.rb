# frozen_string_literal: true

class AddToBeInformedRdvsCountToAgents < ActiveRecord::Migration[6.0]
  def change
    add_column :agents, :to_be_informed_rdv_count, :int, default: 0
  end
end
