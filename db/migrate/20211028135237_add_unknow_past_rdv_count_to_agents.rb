# frozen_string_literal: true

class AddUnknowPastRdvCountToAgents < ActiveRecord::Migration[6.0]
  def change
    add_column :agents, :unknow_past_rdv_count, :int, default: 0

    Rdv.status("unknown_past").joins(:agents_rdvs).group("agents_rdvs.agent_id").count.each do |agent_id, unknow_past_rdv_count|
      Agent.find(agent_id).update(unknow_past_rdv_count: unknow_past_rdv_count)
    end
  end
end
