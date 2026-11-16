class AddTokenExpiredToOutlookConfigs < ActiveRecord::Migration[8.1]
  def change
    add_column :outlook_configs, :token_expired, :boolean, default: false, null: false
    add_column :outlook_configs, :token_refresh_error_description, :text
  end
end
