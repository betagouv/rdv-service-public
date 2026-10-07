class AddCaldavCtagToCaldavConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :caldav_configs, :caldav_ctag, :string
  end
end
