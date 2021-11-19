# frozen_string_literal: true

class AddUnknowPastRdvCountToAgents < ActiveRecord::Migration[6.0]
  def change
    add_column :agents, :unknow_past_rdv_count, :int, default: 0
  end
end
