class AddNotificationsEnabledToAmiHashes < ActiveRecord::Migration[8.0]
  def change
    add_column :ami_france_connect_hashes, :notify_by_ami, :boolean, default: false, null: false
  end
end
