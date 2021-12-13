# frozen_string_literal: true

class RenameUnknowPastRdvCounterForAgent < ActiveRecord::Migration[6.0]
  def change
    rename_column :agents, :unknow_past_rdv_count, :unknown_past_rdv_count
  end
end
