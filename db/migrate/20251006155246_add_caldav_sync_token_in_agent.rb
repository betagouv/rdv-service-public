class AddCaldavSyncTokenInAgent < ActiveRecord::Migration[7.2]
  def change
    add_column :agents, :caldav_sync_token, :string
  end
end
