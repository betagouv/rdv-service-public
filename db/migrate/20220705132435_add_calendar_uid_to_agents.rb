# frozen_string_literal: true

class AddCalendarUidToAgents < ActiveRecord::Migration[6.1]
  def change
    add_column :agents, :calendar_uid, :string, comment: "the uid used for the url of the agent's ics calendar"
    add_index :agents, :calendar_uid, unique: true
  end
end
